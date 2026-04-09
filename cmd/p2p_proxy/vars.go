package main

import (
	"bytes"
	"io"
	"log"
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"github.com/klauspost/compress/s2"
)

/**
MaxConcurrentTasks (系统容量限制)
	含义：这是你设置的瞬时并发上限（例如 2000 或 5000）。
	作用：它限制了同一时刻（毫秒级）有多少个 Goroutine 可以同时运行。
	类比：这就像银行的柜台窗口数量。如果有 10 个窗口，那么同一瞬间只能服务 10 个人。
	代码位置：体现在 tryAcquireTask() —— 如果当前正在运行的任务数达到这个值，新请求会被直接拒绝（熔断）。
	超过此数量将拒绝新请求，触发 Agent 端熔断/重试

stats.RequestCount / 日志中的 Reqs (吞吐量统计)
	含义：这是过去 60秒内 累计接收并处理的请求总次数。
	作用：它反映了业务的繁忙程度（QPS 流量）。
	类比：这就像银行一小时内总共接待了多少客户。即便只有 10 个窗口，如果每个人只办业务 1 分钟，一小时也能接待 600 人。
	代码位置：体现在 atomic.AddInt64(&stats.RequestCount, 1) —— 每来一个请求记一次数，每 60 秒清零重计。

*/

// MaxConcurrentTasks ✅ 最大并发任务数阈值 (根据服务器性能调整)
var MaxConcurrentTasks = int32(4000) // 可根据实际情况调整

// 存储已连接的客户端 PeerID
// Key: "user_id" + "_" + "shopid"
// Value: peer.ID
var (
	// Key: "user_id" + "_" + "shopid", Value: peer.ID
	clientPeers sync.Map

	// ✅ 新增：反向映射 Key: peer.ID (string), Value: "user_id" + "_" + "shopid"
	peerClients sync.Map

	// ✅ 新增：统计数据映射 Key: "user_id" + "_" + "shopid", Value: *ClientStats
	clientStatsMap sync.Map

	// ✅ 新增：全局活跃任务计数器
	activeTaskCount atomic.Int32

	P2PDebug = 0
)

// === 内存优化 0: 初始化内存调优与监控 ===

// initMemTuning 初始化内存调优与监控
// 优化版：引入指数退避 (Exponential Backoff) 策略
// 防止在内存无法回收时（全活跃对象）反复触发无效 GC，导致 CPU 浪费和日志刷屏
func initMemTuning() {
	// 从环境读取或使用默认值（单位 MB）
	// 默认 512MB。如果你的活跃连接对应 117MB 左右的 HeapAlloc，
	// 建议至少给到 256MB+ 以避免触碰阈值。
	memMB := 512 // 默认 512MB
	if v := os.Getenv("P2P_GOMEMLIMIT_MB"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			memMB = n
		}
	}

	// 计算字节限制
	memLimit := int64(memMB) * 1024 * 1024

	// 设置 Go 运行时的软限制 (Go 1.19+)
	// 这比手动的 GCPercent 调整更有效且平滑
	debug.SetMemoryLimit(memLimit)

	// GOGC 默认值（百分比），可通过 env 覆盖
	defaultGOGC := 100
	if v := os.Getenv("P2P_GOGC"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			defaultGOGC = n
		}
	}
	debug.SetGCPercent(defaultGOGC)

	log.Printf("[Init] 内存调优: Limit=%dMB, GOGC=%d, OverloadThreshold=%.1fMB (90%%)",
		memMB, defaultGOGC, float64(memMB)*0.9)

	if v := os.Getenv("P2P_DEBUG"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			P2PDebug = n
		}
	}

	// 启动后台监控
	go func(limitBytes int64) {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		// 定义阈值
		lowThresh := float64(limitBytes) * 0.70  // 70% 恢复
		highThresh := float64(limitBytes) * 0.90 // 90% 报警并拒绝连接

		// 状态追踪
		var lastGCForceTime time.Time
		baseCooldown := 20 * time.Second // 基础冷却
		forceGCCooldown := baseCooldown
		isOverloaded := false
		ineffectiveGCCount := 0 // 连续无效 GC 计数

		for range ticker.C {
			var ms runtime.MemStats
			runtime.ReadMemStats(&ms)
			heapUsage := float64(ms.HeapAlloc)

			// 抽样日志
			if P2PDebug == 1 {
				if time.Now().Unix()%60 < 5 {
					// 第一个 %s：HeapAlloc 的可读字符串（当前已分配并在使用的 Go 堆内存）。
					// 		当前实际在用的堆内存（对象占用）。如果持续增长说明有活跃分配或泄漏。
					// 第二个 %s：HeapSys 的可读字符串（Go 为堆向操作系统申请的总内存，包含已用、未用与碎片）。
					// 		运行时从 OS 拿到的堆内存，通常 ≥ HeapAlloc。两者差距大时可能有内存碎片化或大对象/池被保留没释放回 OS。
					// 第三个 %d：GCs 的次数（自进程启动以来完成的垃圾回收次数，来自 ms.NumGC）。
					// 		垃圾回收已执行的次数。GC 频繁且 CPU 占用飙升，说明分配速率高或内存接近限制（可能触发更激进的 GC）。
					log.Printf("[memmon] Alloc=%.2fMB Sys=%.2fMB GCs=%d Overload=%v NextGCWait=%v",
						heapUsage/1024/1024, float64(ms.HeapSys)/1024/1024, ms.NumGC, isOverloaded, forceGCCooldown)
				}
			}

			// === 触发过载保护 ===
			if heapUsage >= highThresh {
				if !isOverloaded {
					log.Printf("⚠️ [memmon] 内存高负载 (%.2fMB >= %.2fMB)，开启熔断保护",
						heapUsage/1024/1024, highThresh/1024/1024)
					atomic.StoreInt32(&overloadMode, 1)
					isOverloaded = true
				}

				// 检查冷却时间
				if time.Since(lastGCForceTime) < forceGCCooldown {
					continue
				}

				// === 执行强制 GC ===
				log.Printf("[memmon] 尝试释放内存: 触发 runtime.GC()")
				beforeGC := ms.HeapAlloc

				// 临时激进 GC
				debug.SetGCPercent(10)
				runtime.GC()
				debug.SetGCPercent(defaultGOGC)
				debug.FreeOSMemory()

				lastGCForceTime = time.Now()

				// 检查效果
				runtime.ReadMemStats(&ms)
				afterGC := ms.HeapAlloc
				cleaned := int64(beforeGC) - int64(afterGC)

				log.Printf("[memmon] GC 完成: 清理了 %.2fMB. 当前: %.2fMB",
					float64(cleaned)/1024/1024, float64(afterGC)/1024/1024)

				// 🧠 智能策略：指数退避
				if cleaned < 5*1024*1024 {
					// 如果清理掉的内存小于 5MB，说明几乎全是活跃对象
					ineffectiveGCCount++

					// 冷却时间翻倍，最大不超过 10 分钟
					newCooldown := baseCooldown * time.Duration(1<<ineffectiveGCCount) // 20s, 40s, 80s, 160s...
					if newCooldown > 10*time.Minute {
						newCooldown = 10 * time.Minute
					}
					forceGCCooldown = newCooldown

					log.Printf("⚠️ [memmon] GC 效果不佳 (连续%d次)，系统已满载，下次强制 GC 延迟到 %v 后",
						ineffectiveGCCount, forceGCCooldown)
				} else {
					// 如果有效果，重置计数
					ineffectiveGCCount = 0
					forceGCCooldown = baseCooldown
				}

			} else if heapUsage <= lowThresh {
				// === 恢复正常 ===
				if isOverloaded {
					log.Printf("✅ [memmon] 内存恢复正常 (%.2fMB < %.2fMB)，关闭熔断保护",
						heapUsage/1024/1024, lowThresh/1024/1024)
					atomic.StoreInt32(&overloadMode, 0)
					isOverloaded = false

					// 重置所有策略
					forceGCCooldown = baseCooldown
					ineffectiveGCCount = 0
				}
			}
		}
	}(memLimit)
}

// 辅助函数
func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// === 内存优化 1: 内存过载保护机制 ===

// 全局标志：内存过载模式（1=过载，0=正常）
// handler 可读取此变量决定是否拒绝新连接（可选）
var overloadMode int32

// ✅ 新增：bytes.Buffer 池，用于复用 HTTP 请求体的读写缓冲
var bytesBufferPool = sync.Pool{
	New: func() interface{} {
		return new(bytes.Buffer)
	},
}

// ===========================

// === 内存优化 2: 并发配额控制机制 ===

// ✅ 尝试获取资源配额
// 返回 true 表示允许处理，false 表示负载过高需拒绝
func tryAcquireTask() bool {
	current := activeTaskCount.Load()
	if current >= int32(MaxConcurrentTasks) {
		return false
	}
	activeTaskCount.Add(1)
	return true
}

// ✅ 新增：释放资源配额
func releaseTask() {
	activeTaskCount.Add(-1)
}

// ===========================

// === 内存优化 3: 引入 Buffer Pool ===
// 全局缓冲池（32KB）
var bufPool = sync.Pool{
	New: func() interface{} {
		// 使用 32KB 缓冲区，与 io.Copy 默认一致，但可复用
		b := make([]byte, 32*1024)
		return &b
	},
}

// ===========================

// === 内存优化 4: 有界缓存机制 压缩器/缓冲复用池  ===
// 使用 chan 代替 sync.Pool，当 Channel 满时直接丢弃对象，避免内存中积累成千上万个闲置的 Writer和Reader
// 这种有界缓存机制（Bounded Cache）是通用的高并发优化手段，它牺牲了极端高并发下的一点点 CPU（因为缓存满了需要创建新对象），
// 换取了内存使用的绝对安全（避免 OOM）。它不会影响业务逻辑的正确性。

//
// // sync.Pool
// // 压缩器/缓冲复用池示例（根据你实际使用的压缩库调整 New/Reset/Close）
// // S2 写入器池（复用 *s2.Writer）
// // 注意：s2.Writer 支持 Reset(io.Writer) 和 Flush()
// var s2WriterPool = sync.Pool{
// 	New: func() interface{} {
// 		// 这里示例返回 nil 占位，实际应返回已分配的 *s2.Writer 或 包装器
// 		// 例如: return klauspost/compress/s2.NewWriter(io.Discard)
// 		// return nil
//
// 		// 初始使用 io.Discard，随后 acquire 时会 Reset 到真实 dst
// 		return s2.NewWriter(io.Discard)
// 	},
// }
//
// // ✅ 新增：S2 Reader 池
// var s2ReaderPool = sync.Pool{
// 	New: func() interface{} {
// 		// 创建一个空的 Reader，后续通过 Reset 绑定
// 		return s2.NewReader(nil)
// 	},
// }
//
// // acquireS2Writer 从池中取得一个 *s2.Writer 并绑定到 dst
// func acquireS2Writer(dst io.Writer) *s2.Writer {
// 	v := s2WriterPool.Get()
// 	if v == nil {
// 		return s2.NewWriter(dst)
// 	}
// 	w := v.(*s2.Writer)
// 	// 将 writer 绑定到目标 io.Writer（Reset 会复用内部缓冲）
// 	w.Reset(dst)
// 	return w
// }
//
// // releaseS2Writer 在放回池之前 Flush 并清理对 dst 的引用
// func releaseS2Writer(w *s2.Writer) {
// 	// 尝试 Flush，忽略错误
// 	_ = w.Flush()
// 	// 为避免保留对原始 dst 的引用，将目标重置为 io.Discard
// 	w.Reset(io.Discard)
// 	s2WriterPool.Put(w)
// }
//
// // 辅助函数：获取 Reader
// func acquireS2Reader(r io.Reader) *s2.Reader {
// 	v := s2ReaderPool.Get()
// 	if v == nil {
// 		return s2.NewReader(r)
// 	}
// 	reader := v.(*s2.Reader)
// 	reader.Reset(r)
// 	return reader
// }
//
// // 辅助函数：释放 Reader
// func releaseS2Reader(r *s2.Reader) {
// 	// 解除引用，防止内存泄漏
// 	r.Reset(nil)
// 	s2ReaderPool.Put(r)
// }

var (
	// s2ReaderPool 用于复用解压对象
	// 优化关键：限制 MaxBlockSize 为 64KB (Snappy协议上限)，
	// 避免 S2 默认预分配 1MB+ 的内部缓冲区，大幅降低高并发下的内存消耗。
	s2ReaderPool = sync.Pool{
		New: func() interface{} {
			return s2.NewReader(nil, s2.ReaderMaxBlockSize(64*1024))
		},
	}

	// s2WriterPool 用于复用压缩对象
	s2WriterPool = sync.Pool{
		New: func() interface{} {
			// WriterSnappyCompat 确保输出格式兼容 Snappy
			return s2.NewWriter(nil, s2.WriterSnappyCompat())
		},
	}
)

// acquireS2Reader 从池中获取并重置 Reader
func acquireS2Reader(src io.Reader) *s2.Reader {
	r := s2ReaderPool.Get().(*s2.Reader)
	r.Reset(src)
	return r
}

// acquireS2Writer 从池中获取并重置 Writer
func acquireS2Writer(dst io.Writer) *s2.Writer {
	w := s2WriterPool.Get().(*s2.Writer)
	w.Reset(dst)
	return w
}

// releaseS2Reader 归还 Reader 到池中
func releaseS2Reader(r *s2.Reader) {
	if r != nil {
		r.Reset(nil) // 断开对底层流的引用，防止内存泄漏
		s2ReaderPool.Put(r)
	}
}

// releaseS2Writer 归还 Writer 到池中
func releaseS2Writer(w *s2.Writer) {
	if w != nil {
		_ = w.Flush() // 归还前尝试刷新缓冲区
		w.Reset(nil)  // 断开引用
		s2WriterPool.Put(w)
	}
}

// // chan
// const maxS2WriterCache = 64 // 可根据内存预算调整（例如 16/32/64）
//
// // Writer 缓存容量配置 (例如 64)
// var s2WriterCache = make(chan *s2.Writer, maxS2WriterCache)
//
// // 使用与 Writer 相同的缓存容量配置 (例如 64)
// var s2ReaderCache = make(chan *s2.Reader, maxS2WriterCache)
//
// // acquireS2Writer 从有界缓存取一个 *s2.Writer，若缓存为空则新建。
// // 返回后请务必调用 releaseS2Writer(w) 以便复用或丢弃。
// func acquireS2Writer(dst io.Writer) *s2.Writer {
// 	// 无论缓存是否为空，程序永远能拿到一个可用的 Writer 来处理数据，绝对不会阻塞或失败。
//
// 	select {
// 	case w := <-s2WriterCache: // 尝试从缓存拿
// 		// 复用并绑定新的 dst
// 		w.Reset(dst)
// 		return w
// 	default:
// 		// 缓存空：新建一个 writer（开销可控）
// 		return s2.NewWriter(dst)
// 	}
// }
//
// // releaseS2Writer 在放回缓存前 Flush 并断开对底层 dst 的引用。
// // 若缓存已满则丢弃该 writer，避免无限增长内存占用。
// func releaseS2Writer(w *s2.Writer) {
// 	// 丢弃动作发生在数据传输结束之后，仅仅是为了控制内存池不要无限膨胀。
//
// 	if w == nil {
// 		return
// 	}
// 	// 1. 先确保数据刷入底层连接
// 	// 尝试 Flush 忽略错误
// 	_ = w.Flush()
// 	// 解除对原始 dst 的引用，防止保持大型底层缓冲
// 	w.Reset(io.Discard)
//
// 	// 3. 放回 Pool 供下次复用
// 	// s2WriterCache.Put(w)
//
// 	// 2. 尝试放回缓存
// 	// 放回缓存（非阻塞），缓存满则丢弃 w，让 GC 回收
// 	select {
// 	case s2WriterCache <- w:
// 		// 放回成功
// 	default:
// 		// 丢弃，等待 GC 回收
//
// 		// ⚠️ 缓存满了，仅仅是丢弃 w 这个结构体指针，让 Go 的 GC 去回收内存。
// 		// 此时数据早就发走了。
// 	}
// }
//
// // acquireS2Reader 从有界缓存取一个 *s2.Reader，若缓存为空则新建。
// // 使用后必须调用 releaseS2Reader(r)。
// func acquireS2Reader(src io.Reader) *s2.Reader {
// 	select {
// 	case r := <-s2ReaderCache:
// 		// 复用缓存的 reader，并重置输入源
// 		r.Reset(src)
// 		return r
// 	default:
// 		// 缓存空：新建一个 reader (代价可控)
// 		return s2.NewReader(src)
// 	}
// }
//
// // releaseS2Reader 在放回缓存前断开对底层 src 的引用。
// // 若缓存已满则丢弃该 reader，让 GC 回收。
// func releaseS2Reader(r *s2.Reader) {
// 	if r == nil {
// 		return
// 	}
// 	// ⚠️ 关键：解除对原始 src (可能是 net.Conn) 的引用
// 	// 如果不 Reset，Reader 内部会持有上一个 socket 的引用，导致 socket 无法被 GC
// 	r.Reset(bytes.NewReader(nil))
//
// 	// 放回缓存（非阻塞），缓存满则丢弃
// 	select {
// 	case s2ReaderCache <- r:
// 	default:
// 		// 丢弃，等待 GC 回收
// 	}
// }

// ===========================

// === 使用示例 ===
// 1) 并发配额控制
// 2) S2 Writer 池使用示例
