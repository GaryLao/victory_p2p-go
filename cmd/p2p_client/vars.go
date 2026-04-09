package main

import (
	"log"
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"sync"
	"time"
)

// 进程内去重/并发控制
var (
	updateMu          sync.Mutex
	updatesInProgress map[string]struct{}
	lastAttempt       map[string]time.Time
	// 重复请求的冷却时间，按需调整
	updateDedupWindow = 1 * time.Minute

	P2PDebug = 0
)

// === 内存优化 1: 调整 Go 运行时内存参数 ===

// initMemTuning 调整 Go 运行时内存管理参数并整合周期性维护。
// - 设置 memory limit 与 GOGC（从环境变量可覆盖）
// - 启动单个后台监控 goroutine：5s 抽样，遇到超载时触发智能强制 GC；每 30s 在半阈值以上执行维护回收

// initMemTuning 兼容 Go1.10 的内存调优：不调用 debug.SetMemoryLimit（不可用），
// 使用环境变量作为逻辑阈值进行监控并按需触发 runtime.GC()/debug.FreeOSMemory()。
func initMemTuning() {
	// 逻辑内存限制（仅用于监控/决策，不调用 SetMemoryLimit）
	memMB := 32
	if v := os.Getenv("P2P_GOMEMLIMIT_MB"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			memMB = n
		}
	}
	memLimit := int64(memMB) * 1024 * 1024
	// 设置内存软限制（Go 1.19+）
	// debug.SetMemoryLimit(memLimit)

	// GOGC 可由环境变量覆盖
	defaultGOGC := 100
	if v := os.Getenv("P2P_GOGC"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			defaultGOGC = n
		}
	}
	debug.SetGCPercent(defaultGOGC)

	log.Printf("[Init] 内存调优 (Go1.10兼容): logicalLimit=%dMB, GOGC=%d", memMB, defaultGOGC)

	if v := os.Getenv("P2P_DEBUG"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			P2PDebug = n
		}
	}

	// 启动单个监控协程，包含超载保护与周期性维护（避免和外部重复）
	go func(limitBytes int64, gogc int) {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		lowThresh := float64(limitBytes) * 0.70  // 70% 恢复阈值
		highThresh := float64(limitBytes) * 0.90 // 90% 超载阈值

		var lastGCForce time.Time
		baseCooldown := 20 * time.Second
		forceCooldown := baseCooldown
		var ineffectiveCount uint = 0

		lastMaintenance := time.Now()

		for range ticker.C {
			var ms runtime.MemStats
			runtime.ReadMemStats(&ms)
			heapUsage := float64(ms.HeapAlloc)

			// 简要采样日志（避免过多打印）
			if P2PDebug == 1 {
				if time.Now().Unix()%60 < 5 {
					// 第一个 %s：HeapAlloc 的可读字符串（当前已分配并在使用的 Go 堆内存）。
					// 		当前实际在用的堆内存（对象占用）。如果持续增长说明有活跃分配或泄漏。
					// 第二个 %s：HeapSys 的可读字符串（Go 为堆向操作系统申请的总内存，包含已用、未用与碎片）。
					// 		运行时从 OS 拿到的堆内存，通常 ≥ HeapAlloc。两者差距大时可能有内存碎片化或大对象/池被保留没释放回 OS。
					// 第三个 %d：GCs 的次数（自进程启动以来完成的垃圾回收次数，来自 ms.NumGC）。
					// 		垃圾回收已执行的次数。GC 频繁且 CPU 占用飙升，说明分配速率高或内存接近限制（可能触发更激进的 GC）。
					log.Printf("[memmon] Alloc=%.2fMB Sys=%.2fMB NumGC=%d Overload=%v Cooldown=%v",
						heapUsage/1024/1024, float64(ms.HeapSys)/1024/1024, ms.NumGC, heapUsage >= highThresh, forceCooldown)
				}
			}

			// 超载保护：达到 highThresh 时尝试强制回收（带冷却与指数退避）
			if heapUsage >= highThresh {
				if time.Since(lastGCForce) >= forceCooldown {
					before := ms.HeapAlloc
					log.Printf("[memmon] 超载触发强制 GC: Alloc=%.2fMB >= %.2fMB", heapUsage/1024/1024, highThresh/1024/1024)
					// 再次确保 GOGC 为期望值（防止其他地方覆盖）
					debug.SetGCPercent(gogc)
					runtime.GC()
					debug.FreeOSMemory()
					lastGCForce = time.Now()

					// 评估效果
					runtime.ReadMemStats(&ms)
					after := ms.HeapAlloc
					cleaned := float64(int64(before) - int64(after))
					if cleaned < 5*1024*1024 {
						ineffectiveCount++
						// 指数退避（上限保护）
						forceCooldown = baseCooldown * (1 << ineffectiveCount)
						if forceCooldown > 10*time.Minute {
							forceCooldown = 10 * time.Minute
						}
					} else {
						// 有效清理，重置退避
						ineffectiveCount = 0
						forceCooldown = baseCooldown
					}
					log.Printf("[memmon] 强制 GC 完成: 清理了 %.2fMB, 当前 Alloc=%.2fMB, 下次冷却=%v",
						cleaned/1024/1024, float64(after)/1024/1024, forceCooldown)
				}
			} else if heapUsage <= lowThresh {
				// 恢复正常时重置退避策略
				if ineffectiveCount != 0 || forceCooldown != baseCooldown {
					ineffectiveCount = 0
					forceCooldown = baseCooldown
					// 少量日志以示恢复
					log.Printf("[memmon] 内存已回落至安全区: Alloc=%.2fMB <= %.2fMB", heapUsage/1024/1024, lowThresh/1024/1024)
				}
			}

			// 若堆占用超过周期性维护：每 30s 检查一次， 50% 则执行轻量维护
			if time.Since(lastMaintenance) >= 30*time.Second {
				lastMaintenance = time.Now()
				if heapUsage >= float64(limitBytes)*0.50 {
					log.Printf("[memmon] 周期性维护: Alloc=%.2fMB >= 50%%，执行 GC+FreeOSMemory", heapUsage/1024/1024)
					runtime.GC()
					// FreeOSMemory 在老版本 Go 中可用；调用代价较高但可回收物理内存
					debug.FreeOSMemory()
				}
			}
		}
	}(memLimit, defaultGOGC)
}
