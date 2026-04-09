package main

/**
p2p_proxy 是一个基于 LibP2P 的代理服务器，允许通过 P2P 网络访问本地运行的 Web 服务（如 IIS/Apache/Nginx + PHP）。
它与 p2p_agent 配合使用，p2p_agent 运行在远程服务器上，负责将 HTTP 请求通过 P2P 网络转发到 p2p_proxy。

主要功能：
1. 使用 LibP2P 创建 P2P 节点，监听来自 p2p_agent 的连接。
2. 维护客户端的 PeerID 映射关系，支持多用户多店铺的代理请求。
3. 提供 HTTP 代理接口，接收来自外部的 HTTP 请求，并通过 P2P 网络转发到对应的 p2p_agent。
4. 支持隧道协议，允许通过 P2P 连接访问本地 Web 服务。

使用方法：
1. 启动 p2p_proxy，生成或加载私钥。
2. 启动 HTTP 代理服务，监听指定端口。
3. p2p_agent 连接到 p2p_proxy 并注册身份信息。
4. 外部 HTTP 客户端通过 p2p_proxy 的 HTTP 接口发送请求，p2p_proxy 将请求转发到对应的 p2p_agent。

注意事项：
- 确保防火墙允许 p2p_proxy 的监听端口。
- p2p_agent 和 p2p_proxy 需要使用相同的协议版本。
- 生产环境建议配置更严格的资源管理和安全策略。

1. 支持多少个连接（并发连接数）
	理论上，Go 语言处理并发连接的能力非常强（基于 Goroutine），但在实际生产环境中，受限于以下因素：
		文件句柄限制 (File Descriptors): Linux 默认通常是 1024，高并发服务器通常需要调整到 65535 或更高 (ulimit -n)。
		内存消耗: 每个 TCP 连接和 Goroutine 都会占用少量内存。
		Libp2p 默认限制: libp2p 有默认的资源管理器（Resource Manager）来防止 DoS 攻击。
	估算值：
		默认配置下: 几百到一千个活跃连接通常没问题。
		优化配置后: 单台服务器可以轻松支持 1万 - 10万+ 并发连接（取决于服务器内存和带宽）。

2. 每个连接支持多大的传输字节
	没有硬性限制。
		流式传输: 代码中使用的是 io.Copy 进行双向数据转发。这是一种流式操作，数据是边读边写的，不会一次性把整个文件加载到内存中。
		限制因素:
		超时时间: 代码中设置了 IdleConnTimeout (90s) 和读写超时。如果传输大文件导致长时间没有 I/O 动作（例如网络卡顿），可能会触发超时。
		带宽: 取决于服务器的上行带宽。

	结论: 在一个底层的 P2P 连接内，并发几百个 HTTP 请求（Stream）是完全没有问题的。libp2p 的多路复用机制（如 Yamux）非常高效。

3. 一个连接内支持多少个 p2p_agent 的并发访问
	这里需要区分 物理连接 (Connection) 和 逻辑流 (Stream)。
		物理连接: p2p_agent 和 p2p_proxy 之间通常只维护 1 个 底层物理连接（TCP/QUIC）。
		逻辑流 (Stream): libp2p 支持在一个物理连接上复用多个流（Stream Multiplexing）。
			当你在 p2p_agent 端发起 HTTP 请求时，代码 h.NewStream 会在现有的物理连接上创建一个新的轻量级 Stream。
	并发能力：
		Libp2p 默认限制: 默认情况下，libp2p 允许每个 Peer 之间有大量的并发流。
		代码限制: 在 cmd/p2p_agent/main.go 的 http.Transport 中，你设置了：
			MaxIdleConns:          100,
			这意味着连接池最多维护 100 个空闲连接。
	结论: 在一个底层的 P2P 连接内，并发几百个 HTTP 请求（Stream）是完全没有问题的。libp2p 的多路复用机制（如 Yamux）非常高效。

4. 连接的稳定性
	结论: 连接的稳定性主要取决于网络质量和服务器资源。libp2p 本身设计用于不稳定网络环境，能够自动重连和修复连接。

5. 其他注意事项
	- 资源管理: 生产环境中建议配置 libp2p 的资源管理器，防止单个节点消耗过多资源。
	- 心跳机制: 可以实现心跳机制，确保连接的活跃性。
	- 日志和监控: 建议集成日志和监控系统，实时了解连接状态和性能指标。
*/

// 额外：快速排查命令（在开发机/本地运行）
// go tool pprof -http=:8080 http://poslink.4080517.com:8686/debug/pprof/heap?seconds=30

// go tool pprof -http=:8080 http://localhost:8686/debug/pprof/heap
// go tool pprof http://localhost:8686/debug/pprof/goroutine?seconds=30
// go tool pprof http://localhost:8686/debug/pprof/profile?seconds=30

// 获取 goroutine 堆栈：go tool pprof http://localhost:8686/debug/pprof/goroutine`，看哪些 goroutine 卡在 syscall/os.ReadDir/net` 等。
// CPU 采样：`go tool pprof http://localhost:8686/debug/pprof/profile?seconds=30`。
// 确认每个 handler 已正确调用 releaseTask()（任何早退/错误分支都必须释放）。

// 运行堆快照并检查 live objects：go tool pprof http://localhost:8686/debug/pprof/heap`，在 pprof 交互里用 top -inuse_space/list <func>` 找到占用热点。</func>

// 先做 heap profile：go tool pprof http://localhost:8686/debug/pprof/heap`，在 pprof 用 top -inuse_space` 查热区。
// 针对发现的函数/类型优化后再次采 CPU/profile 30s：go tool pprof http://localhost:8686/debug/pprof/profile?seconds=30`，确认 runtime.scanobject` 等占比下降。

import (
	"bufio"
	"bytes"
	"context"
	"database/sql" // ✅ 新增：DB 接口
	"encoding/json"
	"flag" // ✅ 新增：命令行参数解析
	"fmt"
	"io"
	"log"
	"net" // 新增：需要 net 包进行本地 Dial
	"net/http"
	_ "net/http/pprof" // ✅ 新增：引入 pprof，自动注册调试路由
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic" // ✅ 引入 atomic
	"time"

	// "github.com/klauspost/compress/s2"
	// "github.com/klauspost/compress/snappy"
	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p/core/crypto"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	multiaddr "github.com/multiformats/go-multiaddr"

	// "github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/protocol"
	rcmgr "github.com/libp2p/go-libp2p/p2p/host/resource-manager" // 新增
	"github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/relay"    // ✅ 新增：引入 relay 包配置资源

	_ "github.com/lib/pq" // ✅ 新增：PostgreSQL 驱动
)

const (
	AppTitle = "P2P_Proxy_Server"
	AppName  = "p2p_proxy"

	ProtocolPrefix = "p2p_proxy"

	ProtocolVersion = "1.0.0"
	P2PProtocol     = "/" + ProtocolPrefix + "/" + ProtocolVersion

	// TunnelProtocol 新增：定义隧道协议 ID
	TunnelProtocol = "/" + ProtocolPrefix + "/tunnel/" + ProtocolVersion

	PostgresTunnelProtocol = "/" + ProtocolPrefix + "/pgtunnel/1.0.0" // ✅ 新增：用于 PostgreSQL 隧道

	// VNCRelayProtocol 新增：VNC 中继协议 (Agent A -> Proxy)
	VNCRelayProtocol = "/" + ProtocolPrefix + "/vnc_relay/1.0.0"
	// VNCTargetProtocol 新增：VNC 目标协议 (Proxy -> Agent B)
	VNCTargetProtocol = "/" + ProtocolPrefix + "/vnc_target/1.0.0"

	// VNCPeerInfoProtocol
	// 说明: 增加一个“信令”协议，返回目标 B 的 peer.ID 和 multiaddr。
	// 		A 通过该信息直接连接 B，VNC 数据不再走 Proxy 中继。
	VNCPeerInfoProtocol = "/" + ProtocolPrefix + "/vnc_peerinfo/1.0.0"

	// PostgresRelayProtocol 新增：PostgreSQL 协议定义
	PostgresRelayProtocol    = "/" + ProtocolPrefix + "/pg_relay/1.0.0"
	PostgresTargetProtocol   = "/" + ProtocolPrefix + "/pg_target/1.0.0"
	PostgresPeerInfoProtocol = "/" + ProtocolPrefix + "/pg_peerinfo/1.0.0"

	ListenPort           = 8590 // 用于 P2P_Agent 连接的监听端口
	getStoreDataHttpPort = 8686 // 用于访问门店 Web 服务的 HTTP 代理端口
	BkeyFileName         = "" + AppName + ".key"
)

// 全局调试开关
var debugMode bool

// debugLog 仅在 debugMode=true 时打印日志
func debugLog(format string, v ...interface{}) {
	if debugMode {
		log.Printf(format, v...)
	}
}

// writeDailyLog 写入按天滚动的日志，并自动清理 10 天前的旧日志
// prefix: 文件名前缀 (例如 "p2p_proxy_stats")，会自动拼接 "_YYYY-MM-DD.log"
// content: 要写入的日志内容
func writeDailyLog(prefix, content string) {
	logDir := "log"
	_ = os.MkdirAll(logDir, 0755)

	// 生成当日文件名，例如: log/p2p_proxy_stats_2023-10-27.log
	// 格式: prefix_YYYY-MM-DD.log
	logName := fmt.Sprintf("%s_%s.log", prefix, time.Now().Format("2006-01-02"))
	logPath := filepath.Join(logDir, logName)

	// 追加写入模式打开
	if lf, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
		defer lf.Close()
		_, _ = lf.WriteString(content)
	}

	// 放到startLogCleaner处理，一天清理一次
	//
	// // 异步清理过期日志 (保留10天)
	// go func() {
	// 	cutoff := time.Now().AddDate(0, 0, -10)
	// 	entries, _ := os.ReadDir(logDir)
	// 	for _, entry := range entries {
	// 		// 仅处理 prefix_ 开头的文件
	// 		if !entry.IsDir() && strings.HasPrefix(entry.Name(), prefix+"_") {
	// 			if info, err := entry.Info(); err == nil && info.ModTime().Before(cutoff) {
	// 				_ = os.Remove(filepath.Join(logDir, entry.Name()))
	// 			}
	// 		}
	// 	}
	// }()
}

// startLogCleaner 每天运行一次清理任务
func startLogCleaner() {
	exeName := getExecutableName()
	prefixes := []string{exeName, exeName + "_status", exeName + "_status_all"} // 这里可以根据需要调整前缀

	// 定义清理逻辑
	clean := func() {
		logDir := "log"
		cutoff := time.Now().AddDate(0, 0, -10)
		entries, err := os.ReadDir(logDir)
		if err != nil {
			return
		}
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			info, err := entry.Info()
			if err != nil {
				continue
			}
			// if info.ModTime().Before(cutoff) {
			// 	os.Remove(filepath.Join(logDir, entry.Name()))
			// }

			// // 仅处理 prefix_ 开头的文件
			// if strings.HasPrefix(entry.Name(), prefix+"_") {
			// 	if info.ModTime().Before(cutoff) {
			// 		_ = os.Remove(filepath.Join(logDir, entry.Name()))
			// 	}
			// }
			// 检查文件名是否匹配任一前缀
			matchesPrefix := false
			for _, prefix := range prefixes {
				if strings.HasPrefix(entry.Name(), prefix+"_") {
					matchesPrefix = true
					break
				}
			}

			if matchesPrefix && info.ModTime().Before(cutoff) {
				_ = os.Remove(filepath.Join(logDir, entry.Name()))
			}
		}
	}

	// 启动时先清理一次
	clean()

	// 每天执行一次
	ticker := time.NewTicker(24 * time.Hour)
	for range ticker.C {
		clean()
	}
}

// ✅ 新增：获取或创建统计对象
func getStats(key string) *ClientStats {
	v, ok := clientStatsMap.Load(key)
	if ok {
		return v.(*ClientStats)
	}
	s := &ClientStats{}
	actual, _ := clientStatsMap.LoadOrStore(key, s)
	return actual.(*ClientStats)
}

// // 放在文件顶部或 main() 开头调用：initMemTuning()
// func initMemTuning() {
// 	// 从环境读取或使用默认值（单位 MB）
// 	memMB := 512 // 默认 512MB
// 	if v := os.Getenv("P2P_GOMEMLIMIT_MB"); v != "" {
// 		if n, err := strconv.Atoi(v); err == nil && n > 0 {
// 			memMB = n
// 		}
// 	}
// 	// GOGC 默认值（百分比），可通过 env 覆盖
// 	gogc := 100
// 	if v := os.Getenv("P2P_GOGC"); v != "" {
// 		if n, err := strconv.Atoi(v); err == nil {
// 			gogc = n
// 		}
// 	}
//
// 	memLimit := int64(memMB) * 1024 * 1024
// 	prevLimit := debug.SetMemoryLimit(memLimit)
// 	prevGOGC := debug.SetGCPercent(gogc)
//
// 	log.Printf("memory tuning: SetMemoryLimit=%dMB (prev=%d), SetGCPercent=%d (prev=%d)",
// 		memMB, prevLimit/(1024*1024), gogc, prevGOGC)
//
// 	// // 启动后台监控：定期打印堆信息并在接近上限时降低 GOGC（更频繁回收）
// 	// go func(limitBytes int64) {
// 	// 	ticker := time.NewTicker(5 * time.Second)
// 	// 	defer ticker.Stop()
// 	// 	lowThresh := float64(limitBytes) * 0.75  // 75%
// 	// 	highThresh := float64(limitBytes) * 0.90 // 90%
// 	// 	// 动态阈值默认状态
// 	// 	currentGOGC := gogc
// 	//
// 	// 	for range ticker.C {
// 	// 		var ms runtime.MemStats
// 	// 		runtime.ReadMemStats(&ms)
// 	// 		heap := int64(ms.HeapAlloc)
// 	//
// 	// 		// 第一个 %s：HeapAlloc 的可读字符串（当前已分配并在使用的 Go 堆内存）。
// 	// 		// 		当前实际在用的堆内存（对象占用）。如果持续增长说明有活跃分配或泄漏。
// 	// 		// 第二个 %s：HeapSys 的可读字符串（Go 为堆向操作系统申请的总内存，包含已用、未用与碎片）。
// 	// 		// 		运行时从 OS 拿到的堆内存，通常 ≥ HeapAlloc。两者差距大时可能有内存碎片化或大对象/池被保留没释放回 OS。
// 	// 		// 第三个 %d：GCs 的次数（自进程启动以来完成的垃圾回收次数，来自 ms.NumGC）。
// 	// 		// 		垃圾回收已执行的次数。GC 频繁且 CPU 占用飙升，说明分配速率高或内存接近限制（可能触发更激进的 GC）。
// 	// 		log.Printf("[memmon] HeapAlloc=%s HeapSys=%s GCs=%d",
// 	// 			formatBytes(heap), formatBytes(int64(ms.HeapSys)), ms.NumGC)
// 	//
// 	// 		// 当堆超过 highThresh 时，强制触发 GC 并把 GOGC 降得更低以加大回收频率
// 	// 		if float64(heap) >= highThresh {
// 	// 			if currentGOGC != 10 {
// 	// 				log.Printf("[memmon] 高内存占用 >= 90%%，临时降低 GOGC 到 10 并触发 GC")
// 	// 				debug.SetGCPercent(10)
// 	// 				currentGOGC = 10
// 	// 			}
// 	// 			runtime.GC()
// 	// 			continue
// 	// 		}
// 	//
// 	// 		// 当堆回落到低阈值以下，恢复到启动时的 GOGC
// 	// 		if float64(heap) <= lowThresh {
// 	// 			if currentGOGC != gogc {
// 	// 				log.Printf("[memmon] 内存回落 <= 75%%，恢复 GOGC 到 %d", gogc)
// 	// 				debug.SetGCPercent(gogc)
// 	// 				currentGOGC = gogc
// 	// 			}
// 	// 		}
// 	// 	}
// 	// }(memLimit)
// 	go func(limitBytes int64) {
// 		ticker := time.NewTicker(5 * time.Second)
// 		defer ticker.Stop()
//
// 		lowThresh := float64(limitBytes) * 0.75  // 75%
// 		highThresh := float64(limitBytes) * 0.90 // 90%
//
// 		currentGOGC := gogc
// 		lastAdjust := time.Now().Add(-time.Minute) // 使第一次可以立即调整
// 		cooldown := 15 * time.Second               // 每次调整后的冷却时间
//
// 		for range ticker.C {
// 			var ms runtime.MemStats
// 			runtime.ReadMemStats(&ms)
// 			heap := int64(ms.HeapAlloc)
//
// 			// 第一个 %s：HeapAlloc 的可读字符串（当前已分配并在使用的 Go 堆内存）。
// 			// 		当前实际在用的堆内存（对象占用）。如果持续增长说明有活跃分配或泄漏。
// 			// 第二个 %s：HeapSys 的可读字符串（Go 为堆向操作系统申请的总内存，包含已用、未用与碎片）。
// 			// 		运行时从 OS 拿到的堆内存，通常 ≥ HeapAlloc。两者差距大时可能有内存碎片化或大对象/池被保留没释放回 OS。
// 			// 第三个 %d：GCs 的次数（自进程启动以来完成的垃圾回收次数，来自 ms.NumGC）。
// 			// 		垃圾回收已执行的次数。GC 频繁且 CPU 占用飙升，说明分配速率高或内存接近限制（可能触发更激进的 GC）。
// 			log.Printf("[memmon] HeapAlloc=%s HeapSys=%s GCs=%d",
// 				formatBytes(heap), formatBytes(int64(ms.HeapSys)), ms.NumGC)
//
// 			// 高内存处理：分阶段降低 GOGC，带冷却，触发一次 GC 并尝试释放 OS 内存
// 			if float64(heap) >= highThresh {
// 				// 标记过载模式，handler 可拒绝新任务以缓解分配
// 				atomic.StoreInt32(&overloadMode, 1)
//
// 				// 防止频繁调整
// 				if time.Since(lastAdjust) < cooldown {
// 					continue
// 				}
//
// 				// 分阶段调整策略（避免一次性降到 10 导致超高 CPU）
// 				switch {
// 				case currentGOGC > 50:
// 					currentGOGC = maxInt(50, gogc/2)
// 				case currentGOGC > 20:
// 					currentGOGC = 20
// 				default:
// 					// 最后手段才降到 10
// 					currentGOGC = 10
// 				}
//
// 				debug.SetGCPercent(currentGOGC)
// 				log.Printf("[memmon] 高内存占用 >= %.0f%%，将 GOGC 临时调整为 %d (冷却 %s)，触发一次 GC",
// 					highThresh/float64(limitBytes)*100, currentGOGC, cooldown)
// 				// 触发一次 GC（可能产生短时 CPU），但由于分阶段与冷却，避免持续高负载
// 				runtime.GC()
//
// 				// 异步尝试释放未被使用的内存回操作系统（代价可控）
// 				go func() {
// 					time.Sleep(300 * time.Millisecond)
// 					debug.FreeOSMemory()
// 				}()
//
// 				lastAdjust = time.Now()
// 				continue
// 			}
//
// 			// 低内存：恢复到启动时配置
// 			if float64(heap) <= lowThresh {
// 				if atomic.LoadInt32(&overloadMode) == 1 {
// 					atomic.StoreInt32(&overloadMode, 0)
// 				}
// 				if currentGOGC != gogc {
// 					debug.SetGCPercent(gogc)
// 					currentGOGC = gogc
// 					lastAdjust = time.Now()
// 					log.Printf("[memmon] 内存回落 <= 75%%，恢复 GOGC 到 %d", gogc)
// 				}
// 			}
// 		}
// 	}(memLimit)
//
// }

func main() {
	//antigravity add 2026-01-23 19:27:17
	// === 全局 Panic 恢复机制 ===
	// 捕获所有未处理的 panic，记录详细堆栈信息，防止程序突然崩溃退出
	defer func() {
		if r := recover(); r != nil {
			// 获取堆栈信息
			buf := make([]byte, 4096)
			n := runtime.Stack(buf, false)
			stackTrace := string(buf[:n])

			// 记录错误日志
			log.Printf("🔴🔴🔴 程序发生严重错误 (Panic) 🔴🔴🔴")
			log.Printf("错误信息: %v", r)
			log.Printf("堆栈跟踪:\n%s", stackTrace)

			// 可选：写入独立的崩溃日志文件
			crashLogFile := fmt.Sprintf("crash_%s.log", time.Now().Format("20060102_150405"))
			crashContent := fmt.Sprintf("时间: %s\n错误: %v\n堆栈:\n%s",
				time.Now().Format("2006-01-02 15:04:05"), r, stackTrace)
			os.WriteFile(crashLogFile, []byte(crashContent), 0644)

			log.Printf("💾 崩溃日志已保存到: %s", crashLogFile)
			log.Printf("⚠️ 程序即将退出，请检查日志并修复问题后重新启动")

			// 给日志缓冲区时间写入
			time.Sleep(500 * time.Millisecond)
		}
	}()
	// === 全局 Panic 恢复机制结束 ===

	// ✅ 新增：解析命令行参数
	flag.BoolVar(&debugMode, "debug", false, "开启详细调试日志 (Show [Poke], [AddrSync] etc.)")
	flag.Parse()

	initMemTuning() // ✅ 新增：初始化内存调优

	// 1. 初始化日志 (按日保存，保留10个)
	setupLog() // ✅ 新增

	// ✅ 新增：启动独立的日志清理协程
	go startLogCleaner()

	// 2. 设置窗口标题 (用于 p2p_monitor 识别)
	setConsoleTitle(AppTitle)

	log.Printf("🚀 " + AppName + " 启动中...")

	ctx := context.Background()

	// 1. 加载私钥
	priv := loadAndGeneratorServerBKey()

	// === 新增：放宽资源限制 ===
	// 针对 8GB 内存服务器的保守配置
	// 使用 DefaultLimits.Scale 自动生成适合 2GB 内存的配置
	// 这种方式避免了直接访问结构体字段可能导致的 "undefined" 错误，且配置更科学

	// 1. 定义资源预算
	// 内存限制: 2GB (2 * 1024 * 1024 * 1024)
	// 降低内存限制到 500M (即使服务器有 8GB，作为单个进程也应限制，防止 Go GC 不及时)
	// 针对 Ubuntu 22.04 通用 VPS 配置 (建议设为物理内存的 1/4 到 1/2)
	// 原来的 2GB 对于小内存机器太大了，改为 512MB
	//
	// 文件句柄: 65535 (假设系统已调优，若未调优可设为 1024)
	// var memoryLimit int64 = 2 * 1024 * 1024 * 1024  // 2G
	var memoryLimit int64 = 512 * 1024 * 1024 // 512M
	var fdLimit int = 65535

	if v := os.Getenv("P2P_GOMEMLIMIT_MB"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			memoryLimit = int64(n) * 1024 * 1024
		}
	}

	// 2. 生成具体限制配置
	// Scale 方法会根据内存预算，自动计算出 System.Conns, System.Streams 等合理值
	limits := rcmgr.DefaultLimits.Scale(memoryLimit, fdLimit)

	// // ✅ 修复：使用 LimitConfig 来配置限制，而不是直接访问私有字段
	// // 创建自定义限制配置
	// config := rcmgr.PartialLimitConfig{}
	// config.System.ConnsInbound = 1024
	// config.System.ConnsOutbound = 1024
	// config.System.StreamsInbound = 2048
	// config.System.StreamsOutbound = 2048
	// // 应用配置到 limits
	// limits = config.Build(limits)

	// 3. 创建 Limiter
	limiter := rcmgr.NewFixedLimiter(limits)

	rm, err := rcmgr.NewResourceManager(limiter)
	if err != nil {
		log.Fatalf("致命错误：创建资源管理器失败: %v", err)
	}

	// ✅ V11 升级：彻底开放 Relay V2 资源配额
	// 针对多门店高并发场景，解决任何可能的 NO_RESERVATION (204)
	relayResources := relay.DefaultResources()
	relayResources.MaxReservations = 8192     // 提升总预约位
	relayResources.MaxReservationsPerIP = 512 // 极大放宽单 IP 限制，解决同出口多 Agent 问题
	relayResources.MaxCircuits = 4096         // 提升并发电路数
	relayResources.BufferSize = 2048          // 优化内存占用
	relayResources.Limit = &relay.RelayLimit{
		Duration: 24 * time.Hour,          // 允许超长连接 (1天)
		Data:     10 * 1024 * 1024 * 1024, // 允许海量数据 (10GB)
	}

	// 2. 创建 LibP2P Host
	h, err := libp2p.New(
		libp2p.ListenAddrStrings(
			fmt.Sprintf("/ip4/0.0.0.0/tcp/%d", ListenPort),
			fmt.Sprintf("/ip4/0.0.0.0/udp/%d/quic-v1", ListenPort), // ✅ 新增：支持 QUIC 打洞
		),
		libp2p.Identity(priv),
		libp2p.Ping(true),
		libp2p.ResourceManager(rm), // 应用资源管理器
		libp2p.EnableRelayService(relay.WithResources(relayResources)), // ✅ 修改：开启中继服务并应用宽松配置
		libp2p.EnableHolePunching(),                                    // ✅ 新增：启用打洞协调服务
		libp2p.ForceReachabilityPublic(),                               // ✅ 新增：强制声明为公网可达，解决 270 错误
	)
	if err != nil {
		log.Fatalf("致命错误：启动 P2P Host 失败: %v", err)
	}

	// ✅ 新增：启动自检（确认监听地址，包含 UDP/QUIC）
	log.Printf("[SelfCheck] Proxy 启动成功，PeerID: %s", h.ID())
	log.Printf("[SelfCheck] Proxy 监听列表: %v", h.Addrs())
	for _, addr := range h.Addrs() {
		if strings.Contains(addr.String(), "/udp/") {
			log.Printf("🚀 [SelfCheck] UDP/QUIC 监听已确认: %s", addr)
		}
	}
	// protos := h.Mux().Protocols()
	// sort.Slice(protos, func(i, j int) bool { return protos[i] < protos[j] })
	// log.Printf("[SelfCheck] PeerID=%s", h.ID())
	// log.Printf("[SelfCheck] ListenAddrs=%v", h.Addrs())
	// log.Printf("[SelfCheck] Protocols(%d)=%v", len(protos), protos)

	// ✅ 新增：启动统计上报协程
	go startStatsReporter()

	// 3. 设置流处理器 (处理 p2p_agent 的连接注册)
	// 注册连接保持轻量，通常不限制，以便 Agent 维持心跳
	h.SetStreamHandler(P2PProtocol, func(s network.Stream) {
		handleRegistration(h, s) // ✅ 修复：传入 h
	})

	// === 注册隧道流处理器 ===
	h.SetStreamHandler(TunnelProtocol, func(s network.Stream) {
		// ✅ 修改：隧道处理增加熔断保护
		if !tryAcquireTask() {
			log.Printf("⚠️ [Tunnel] 系统过载 (%d)，拒绝连接: %s", MaxConcurrentTasks, s.Conn().RemotePeer())
			s.Reset() // 立即重置流，Agent 会收到 "stream reset" 错误
			return
		}
		defer releaseTask()

		handleTunnel(s)
	})
	// ============================

	// === 注册 PostgreSQL 隧道流处理器 ===
	// 你可以直接复用 handleTunnel，因为它支持 "IP:Port" 格式
	// 或者你可以写一个简化版的 handlePostgresTunnel
	h.SetStreamHandler(PostgresTunnelProtocol, func(s network.Stream) { // 假设你在 main包也定义了这个常量
		// ✅ 熔断保护
		if !tryAcquireTask() {
			log.Printf("⚠️ [PGTunnel] 系统过载，拒绝连接")
			s.Reset()
			return
		}
		defer releaseTask()

		handleTunnel(s) // 复用现有的逻辑
	})
	// =================================

	// === 注册 VNC 中继流处理器 ===
	h.SetStreamHandler(VNCRelayProtocol, func(s network.Stream) {
		// ✅ 修改：VNC 中继增加熔断保护
		if !tryAcquireTask() {
			log.Printf("⚠️ [Tunnel] 系统过载 (%d)，拒绝连接: %s", MaxConcurrentTasks, s.Conn().RemotePeer())
			s.Reset() // 立即重置流，Agent 会收到 "stream reset" 错误
			return
		}
		defer releaseTask()

		// handleVNCRelay(ctx, h, s)
		handleRelayCommon(ctx, h, s, VNCTargetProtocol, "VNC")
	})
	// =================================

	// === 注册 VNC 直连流处理器 ===
	h.SetStreamHandler(VNCPeerInfoProtocol, func(s network.Stream) {
		// ✅ 修改：VNC 直连增加熔断保护
		if !tryAcquireTask() {
			log.Printf("⚠️ [Tunnel] 系统过载 (%d)，拒绝连接: %s", MaxConcurrentTasks, s.Conn().RemotePeer())
			s.Reset() // 立即重置流，Agent 会收到 "stream reset" 错误
			return
		}
		defer releaseTask()

		// handleVNCPeerInfo(ctx, h, s)
		handlePeerCommon(ctx, h, s, "VNC")
	})

	// === 注册 PostgreSQL 中继流处理器 ===
	h.SetStreamHandler(PostgresRelayProtocol, func(s network.Stream) {
		// 复用逻辑，或者单独写一个 handlePostgresRelay
		handleRelayCommon(ctx, h, s, PostgresTargetProtocol, "PostgreSQL")
	})

	// === 注册 PostgreSQL 直连流处理器 ===
	h.SetStreamHandler(PostgresPeerInfoProtocol, func(s network.Stream) {
		// 复用逻辑，或者单独写一个 handlePostgresRelay
		handlePeerCommon(ctx, h, s, "PostgreSQL")
	})

	// 4. 启动 HTTP 代理服务
	http.HandleFunc("/proxy", func(w http.ResponseWriter, r *http.Request) {
		// ✅ 修改：HTTP 入口增加熔断保护
		if !tryAcquireTask() {
			log.Printf("⚠️ [HTTP] 系统过载，拒绝代理请求")
			http.Error(w, "503 Service Unavailable - Proxy Overloaded", http.StatusServiceUnavailable)
			return
		}
		defer releaseTask()

		handleHttpProxy(ctx, h, w, r)
	})

	go func() {
		if err := http.ListenAndServe(fmt.Sprintf(":%d", getStoreDataHttpPort), nil); err != nil {
			log.Fatalf("致命错误：HTTP 服务启动失败: %v", err)
		}
	}()

	log.Printf("" + AppName + " 启动完成，正在运行中...")
	log.Printf("P2P 监听地址: %s", h.Addrs())
	log.Printf("Peer ID: %s", h.ID())
	log.Printf("HTTP 代理监听端口: %d", getStoreDataHttpPort)

	// 阻塞主线程
	select {}
}

// RegisterTCPProxyHandler 在 p2p_proxy 上注册流处理函数：当收到该协议流时，
// 它连接本机的 PostgreSQL (127.0.0.1:5432) 并做双向拷贝。
func RegisterTCPProxyHandler(s network.Stream) {
	defer s.Close()

	// 可选：设置超时，防止挂死
	deadline := time.Now().Add(30 * time.Second)
	s.SetDeadline(deadline)

	// 连接本地 Postgres（在 p2p_proxy 机器上）
	localConn, err := net.DialTimeout("tcp", "127.0.0.1:5432", 10*time.Second)
	if err != nil {
		log.Printf("无法连接本地 Postgres: %v", err)
		return
	}
	defer localConn.Close()

	// 清除 deadline（进入长连接转发）
	s.SetDeadline(time.Time{})

	// 双向拷贝
	done := make(chan struct{})
	go func() {
		io.Copy(localConn, s) // 从 p2p 流读，写到本地 Postgres
		localConn.(*net.TCPConn).CloseWrite()
		done <- struct{}{}
	}()
	go func() {
		io.Copy(s, localConn) // 从本地 Postgres 读，写回 p2p 流
		s.CloseWrite()
		done <- struct{}{}
	}()
	// 等待任一方向完成
	<-done
}

// 我们可以提取一个通用的中继处理函数，供 VNC 和 PostgreSQL 共用
// 或者你可以直接复制 handleVNCRelay 并改名为 handlePostgresRelay
func handleRelayCommon(ctx context.Context, h host.Host, s network.Stream, targetProto string, serviceName string) {
	defer s.Close()

	// 1. 读取目标身份信息
	s.SetReadDeadline(time.Now().Add(10 * time.Second))
	reader := bufio.NewReader(s)
	line, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ [%s] 读取目标信息失败: %v", serviceName, err)
		return
	}
	s.SetReadDeadline(time.Time{})

	parts := strings.Split(strings.TrimSpace(line), "|")
	if len(parts) != 2 {
		log.Printf("❌ [%s] 目标格式错误: %s", serviceName, line)
		return
	}
	targetKey := parts[0] + "_" + parts[1]

	// 2. 查找目标 PeerID
	val, ok := clientPeers.Load(targetKey)
	if !ok {
		log.Printf("❌ [%s] 目标不在线: %s", serviceName, targetKey)
		return
	}
	// targetPeerID := val.(peer.ID)
	// ✅ 修改: 从结构体提取 PeerID
	targetPeerID := val.(ClientSession).PeerID

	// ✅ 修改：获取统计对象并增加连接数
	stats := getStats(targetKey)
	atomic.AddInt32(&stats.Conns, 1)
	atomic.AddInt64(&stats.RequestCount, 1) // ✅ 新增：记录请求次数
	defer atomic.AddInt32(&stats.Conns, -1)

	log.Printf("🔗 建立 [%s] 桥接: %s -> Proxy -> %s", serviceName, s.Conn().RemotePeer(), targetKey)

	// 3. 连接到目标 Agent
	targetStream, err := h.NewStream(ctx, targetPeerID, protocol.ID(targetProto))
	if err != nil {
		log.Printf("❌ [%s] 连接目标 Agent 失败: %v", serviceName, err)
		return
	}
	defer targetStream.Close()

	// lzm modify 2026-01-08 01:22:12
	// ❌ 已移除 Old StatsStream 包装，改用 copyBuffered
	//
	// // ✅ 修改：包装目标流以统计流量
	// wrappedTarget := &StatsStream{Stream: targetStream, stats: stats}
	//
	// // 4. 双向转发
	// var wg sync.WaitGroup
	// wg.Add(2)
	// go func() { defer wg.Done(); io.Copy(wrappedTarget, s); wrappedTarget.CloseWrite() }()
	// go func() { defer wg.Done(); io.Copy(s, wrappedTarget); s.CloseWrite() }()
	// wg.Wait()
	//
	// ✅ 新代码: 使用 buffer pool 拷贝并统计
	var wg sync.WaitGroup
	wg.Add(2)
	// 从 s (Source/Proxy) 读，写入 target (Agent)，这是 Upload/Egress
	go func() {
		defer wg.Done()
		// 从 Source (s) 读，写入 Target (targetStream) => Upload/Egress
		// ⚠️ 关键修复：从 reader 读，而不是直接从 s 读，防止 bufio 缓冲区内已读数据被吞掉
		copyBuffered(targetStream, reader, stats, false)
		targetStream.CloseWrite()
	}()
	// 从 target (Agent) 读，写入 s (Source/Proxy)，这是 Download/Ingress
	go func() {
		defer wg.Done()
		// 从 Target (targetStream) 读，写入 Source (s) => Download/Ingress
		copyBuffered(s, targetStream, stats, true)
		s.CloseWrite()
	}()
	wg.Wait()

	log.Printf("✅ [%s] 会话结束: %s", serviceName, targetKey)
}

func handlePeerCommon(ctx context.Context, h host.Host, s network.Stream, serviceName string) {
	defer s.Close()

	// 读取目标身份信息: user_id|shopid\n
	s.SetReadDeadline(time.Now().Add(10 * time.Second))
	reader := bufio.NewReader(s)
	line, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ [%s_PeerInfo] 读取目标信息失败: %v", serviceName, err)
		return
	}
	s.SetReadDeadline(time.Time{})

	parts := strings.Split(strings.TrimSpace(line), "|")
	if len(parts) != 2 {
		log.Printf("❌ [%s_PeerInfo] 目标格式错误: %s", serviceName, line)
		return
	}
	targetKey := parts[0] + "_" + parts[1]

	val, ok := clientPeers.Load(targetKey)
	if !ok {
		_, _ = s.Write([]byte("ERR target offline\n"))
		return
	}
	// targetPeerID := val.(peer.ID)
	// ✅ 修改: 从结构体提取 PeerID
	targetPeerID := val.(ClientSession).PeerID

	// ✅ 诊断日志：打印 Proxy 观察到的目标的完整地址库
	debugLog("🔍 [%s_PeerInfo] 目标 %s 的 Peerstore 原始记录: %v", serviceName, targetPeerID.ShortString(), h.Peerstore().Addrs(targetPeerID))

	// 1. 获取物理地址 (用于 P2P 直连打洞)
	// 我们需要收集尽可能多的“直连”路径，排除中继路径。
	var addrMap = make(map[string]bool)
	var addrs []string

	// A. 优先获取当前活跃连接的实时物理地址 (观察到的 NAT 映射地址)
	conns := h.Network().ConnsToPeer(targetPeerID)
	for _, c := range conns {
		if ra := c.RemoteMultiaddr(); ra != nil {
			sAddr := ra.String()
			if !strings.Contains(sAddr, "/p2p-circuit") {
				if !addrMap[sAddr] {
					addrMap[sAddr] = true
					addrs = append(addrs, sAddr)
				}
				// ✅ V9 智能合成：基于已发现的 TCP 端口，推报可能的 UDP 打洞地址
				// 许多 NAT 设备会为 TCP 和 UDP 分配对称的公网 IP，端口也可能相同或临近
				if strings.Contains(sAddr, "/tcp/") {
					udpAddr := strings.Replace(sAddr, "/tcp/", "/udp/", 1)
					if !strings.Contains(udpAddr, "/quic-v1") {
						udpAddr += "/quic-v1"
					}
					if !addrMap[udpAddr] {
						addrs = append(addrs, udpAddr)
						debugLog("🧠 [AddrSynthesis] 基于 TCP 合成 UDP 打洞路径: %s", udpAddr)
					}
				}
			}
		}
	}

	// B. 补充获取 Peerstore 记录的所有观测数据
	// 这包含了 Agent 自身发现的内网地址以及其它节点观测到的地址。
	allPeerAddrs := h.Peerstore().Addrs(targetPeerID)
	for _, a := range allPeerAddrs {
		sAddr := a.String()
		// 同样过滤掉中继地址，避免污染打洞路径
		if !strings.Contains(sAddr, "/p2p-circuit") {
			if !addrMap[sAddr] {
				addrMap[sAddr] = true
				addrs = append(addrs, sAddr)
			}
		}
	}
	// ✅ V12 增强：反向唤醒预留 (Poke-to-Reserve)
	hasRes := false
	for _, a := range h.Peerstore().Addrs(targetPeerID) {
		if strings.Contains(a.String(), "/p2p-circuit") {
			hasRes = true
			break
		}
	}

	if !hasRes {
		// 尝试通过业务流通知目标 Agent 立即执行预约
		// 1. 查找目标的 Key
		targetKey := ""
		peerClients.Range(func(k, v interface{}) bool {
			if k.(string) == targetPeerID.String() {
				targetKey = v.(string)
				return false
			}
			return true
		})

		if targetKey != "" {
			if sess, ok := clientPeers.Load(targetKey); ok {
				session := sess.(ClientSession)
				select {
				case session.CmdChan <- "reserve":
					debugLog("🔔 [Poke] 目标 %s 尚未预留，已下达唤醒信号，进入阻塞等待验证...", targetPeerID.ShortString())

					// ✅ V13 增强：阻塞式验证循环
					// 最多等待 10 秒，每 200ms 检查一次目标的 Peerstore
					// ✅ V15 增强：阻塞式验证循环 (增加到 15s)
					startCheck := time.Now()
					for time.Since(startCheck) < 15*time.Second {
						found := false
						for _, a := range h.Peerstore().Addrs(targetPeerID) {
							if strings.Contains(a.String(), "/p2p-circuit") {
								found = true
								break
							}
						}
						if found {
							debugLog("✅ [Poke] 验证通过！目标 %s 已刷新预留位 (耗时: %v)", targetPeerID.ShortString(), time.Since(startCheck))
							hasRes = true
							break
						}
						time.Sleep(200 * time.Millisecond)
					}
					if !hasRes {
						debugLog("⚠️ [Poke] 等待超时，目标 %s 未能及时完成预留抢占", targetPeerID.ShortString())
					}
				default:
					// 通道满
				}
			}
		}
	}

	// 2. ✅ 新增：添加中继地址 (作为保底和打洞的桥梁)
	relayToTargetStr := fmt.Sprintf("/p2p/%s/p2p-circuit/p2p/%s", h.ID().String(), targetPeerID.String())
	addrs = append(addrs, relayToTargetStr)

	// ✅ V10 诊断日志：检查目标的“预留状态”
	if !hasRes {
		// 再次自检 Peerstore (可能刚才阻塞等待刚好成功)
		for _, a := range h.Peerstore().Addrs(targetPeerID) {
			if strings.Contains(a.String(), "/p2p-circuit") {
				hasRes = true
				break
			}
		}
	}
	if !hasRes {
		debugLog("⚠️ [%s_PeerInfo] 目标 %s 尚未建立中继预留，连接可能报错 204", serviceName, targetPeerID.ShortString())
	}

	if len(addrs) == 0 {
		_, _ = s.Write([]byte("ERR no remote addrs\n"))
		return
	}

	resp := map[string]any{
		"peer_id": targetPeerID.String(),
		"addrs":   addrs,
	}
	b, _ := json.Marshal(resp)
	b = append(b, '\n')
	_, _ = s.Write(b)
}

// 处理 VNC 中继请求
func handleVNCRelay(ctx context.Context, h host.Host, s network.Stream) {
	// ✅ 过载保护与并发限制
	// 1. 如果内存过高（由 memmon 设置），直接拒绝
	if atomic.LoadInt32(&overloadMode) == 1 {
		s.Reset() // 立即重置连接
		return
	}
	// 2. 尝试获取并发配额
	if !tryAcquireTask() {
		log.Printf("⚠️ 并发数超限 (%d)，拒绝 VNC 请求", MaxConcurrentTasks)
		s.Reset()
		return
	}
	defer releaseTask() // 确保退出时释放配额

	defer s.Close()

	// 1. 读取目标身份信息 (格式: user_id|shopid\n)
	// Agent A 会先发送一行文本告诉 Proxy 想连谁
	s.SetReadDeadline(time.Now().Add(10 * time.Second))
	reader := bufio.NewReader(s)
	line, err := reader.ReadString('\n') // 这行会吃掉缓存 s 的第一行数据
	if err != nil {
		log.Printf("❌ 读取 VNC 目标信息失败: %v", err)
		return
	}
	s.SetReadDeadline(time.Time{}) // 清除超时

	parts := strings.Split(strings.TrimSpace(line), "|")
	if len(parts) != 2 {
		log.Printf("❌ VNC 目标格式错误: %s", line)
		return
	}
	targetKey := parts[0] + "_" + parts[1]

	// 2. 查找目标 Agent (B/C/D) 的 PeerID
	val, ok := clientPeers.Load(targetKey)
	if !ok {
		log.Printf("❌ VNC 目标不在线: %s", targetKey)
		return
	}
	// targetPeerID := val.(peer.ID)
	// ✅ 修改: 从结构体提取 PeerID
	targetPeerID := val.(ClientSession).PeerID

	// ✅ 修改：统计
	stats := getStats(targetKey)
	atomic.AddInt32(&stats.Conns, 1)
	atomic.AddInt64(&stats.RequestCount, 1) // ✅ 新增：记录请求次数
	defer atomic.AddInt32(&stats.Conns, -1)

	log.Printf("🔗 建立 VNC 桥接: %s -> Proxy -> %s", s.Conn().RemotePeer(), targetKey)

	// 3. 连接到目标 Agent (B/C/D)
	targetStream, err := h.NewStream(ctx, targetPeerID, VNCTargetProtocol)
	if err != nil {
		log.Printf("❌ 连接目标 Agent 失败: %v", err)
		return
	}
	defer targetStream.Close()

	// lzm modify 2026-01-08 02:01:25
	//
	// // ✅ 修改：包装
	// wrappedTarget := &StatsStream{Stream: targetStream, stats: stats}
	//
	// // 4. 双向转发数据 (桥接两个流)
	// var wg sync.WaitGroup
	// wg.Add(2)
	//
	// go func() {
	// 	defer wg.Done()
	// 	io.Copy(wrappedTarget, s) // A -> Proxy -> B
	// 	wrappedTarget.CloseWrite()
	// }()
	//
	// go func() {
	// 	defer wg.Done()
	// 	io.Copy(s, wrappedTarget) // B -> Proxy -> A
	// 	s.CloseWrite()
	// }()
	//
	// wg.Wait()
	//
	// ✅ 新代码: 使用 buffer pool 拷贝并统计
	var wg sync.WaitGroup
	wg.Add(2)
	// 从 s (Source/Proxy) 读，写入 target (Agent)，这是 Upload/Egress
	go func() {
		defer wg.Done()
		// 从 Source (s) 读，写入 Target (targetStream) => Upload/Egress
		// ⚠️ 关键修复：从 reader 读，而不是直接从 s 读，防止 bufio 缓冲区内已读数据被吞掉
		copyBuffered(targetStream, reader, stats, false)
		targetStream.CloseWrite()
	}()
	// 从 target (Agent) 读，写入 s (Source/Proxy)，这是 Download/Ingress
	go func() {
		defer wg.Done()
		// 从 Target (targetStream) 读，写入 Source (s) => Download/Ingress
		copyBuffered(s, targetStream, stats, true)
		s.CloseWrite()
	}()
	wg.Wait()

	log.Printf("✅ VNC 会话结束: %s", targetKey)
}

// 新增：返回目标 peer 信息
func handleVNCPeerInfo(ctx context.Context, h host.Host, s network.Stream) {
	defer s.Close()

	// 读取目标身份信息: user_id|shopid\n
	s.SetReadDeadline(time.Now().Add(10 * time.Second))
	reader := bufio.NewReader(s)
	line, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ [VNC_PeerInfo] 读取目标信息失败: %v", err)
		return
	}
	s.SetReadDeadline(time.Time{})

	parts := strings.Split(strings.TrimSpace(line), "|")
	if len(parts) != 2 {
		log.Printf("❌ [VNC_PeerInfo] 目标格式错误: %s", line)
		return
	}
	targetKey := parts[0] + "_" + parts[1]

	val, ok := clientPeers.Load(targetKey)
	if !ok {
		_, _ = s.Write([]byte("ERR target offline\n"))
		return
	}
	// targetPeerID := val.(peer.ID)
	// ✅ 修改: 从结构体提取 PeerID
	targetPeerID := val.(ClientSession).PeerID

	// 1. 获取物理地址 (尝试直连用)
	conns := h.Network().ConnsToPeer(targetPeerID)
	var addrs []string
	for _, c := range conns {
		if ra := c.RemoteMultiaddr(); ra != nil {
			addrs = append(addrs, ra.String())
		}
	}

	// 2. ✅ 新增：添加中继地址 (作为保底和打洞的桥梁)
	// 格式: /p2p/<ProxyID>/p2p-circuit
	// 当 Agent A 连接这个地址时，Libp2p 会知道"通过 Proxy 中转去连目标"
	//
	// 	修复：返回“通过 Proxy 中继到目标”的完整地址
	// 这是 relay v2 常用格式：/p2p/<RelayID>/p2p-circuit/p2p/<TargetID>
	relayToTarget := fmt.Sprintf("/p2p/%s/p2p-circuit/p2p/%s", h.ID().String(), targetPeerID.String())
	addrs = append(addrs, relayToTarget)

	if len(addrs) == 0 {
		_, _ = s.Write([]byte("ERR no remote addrs\n"))
		return
	}

	resp := map[string]any{
		"peer_id": targetPeerID.String(),
		"addrs":   addrs,
	}
	b, _ := json.Marshal(resp)
	b = append(b, '\n')
	_, _ = s.Write(b)
}

// === 新增：处理隧道请求 ===
func handleTunnel(s network.Stream) {
	// ✅ 过载保护与并发限制
	if atomic.LoadInt32(&overloadMode) == 1 {
		s.Reset()
		return
	}
	if !tryAcquireTask() {
		s.Reset()
		return
	}
	defer releaseTask()

	defer s.Close()

	// ✅ 修改：根据 RemotePeer 查找对应的商户 Key
	remotePeerID := s.Conn().RemotePeer().String()
	var stats *ClientStats
	if keyVal, ok := peerClients.Load(remotePeerID); ok {
		key := keyVal.(string)
		stats = getStats(key)
		atomic.AddInt32(&stats.Conns, 1)
		atomic.AddInt64(&stats.RequestCount, 1) // ✅ 新增：记录请求次数
		defer atomic.AddInt32(&stats.Conns, -1)
	}

	// 特殊 PeerID 测试逻辑
	// if "QmUsMZEknyqMh8TAa22N7PF2iKEMSaZem23GQyxH2KAt4Q" == remotePeerID {
	// 	log.Printf("⚠️ 警告：模拟测试请求将被拒绝！PeerID: %s", remotePeerID)
	// 	return
	// }

	// // 连接本地 Web 服务 (假设 IIS/Apache/Nginx 运行在 80 端口)
	// // 如果你的 PHP 环境运行在其他端口，请修改此处，例如 "127.0.0.1:8080"
	// targetConn, err := net.Dial("tcp", "127.0.0.1:80")
	// if err != nil {
	// 	log.Printf("❌ 隧道连接本地服务失败: %v", err)
	// 	return
	// }
	// defer targetConn.Close()

	// 设置读取超时，防止恶意连接占用
	// s.SetReadDeadline(time.Now().Add(5 * time.Second))
	s.SetReadDeadline(time.Now().Add(10 * time.Second))

	// 1. 读取握手信息
	// p2p_agent 发送的格式可能是 "port" (旧版) 或 "host:port" (新版)
	// p2p_agent 发送格式: "domain:port\n" (例如: poslink.4080517.com:443\n)
	// 或者旧版格式: "port\n" (例如: 80\n)
	reader := bufio.NewReader(s)
	targetStr, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ 读取隧道目标失败: %v", err)
		return
	}
	// 清除超时设置，后续数据传输不应有超时
	s.SetReadDeadline(time.Time{}) // 清除超时

	targetStr = strings.TrimSpace(targetStr)
	// log.Printf("🔗 targetStr = %s", targetStr)

	// 2. 解析 Host 和 Port 和 Snappy 标志
	var host, port, zip string
	if strings.Contains(targetStr, ":") {
		// 格式: domain:port|zip (例如: pay.4080517.com:443|1)
		// 先尝试分离 zip 标志
		parts := strings.Split(targetStr, "|")
		addrPart := parts[0]
		zip = "0"
		if len(parts) > 1 {
			zip = parts[1]
		}

		h, p, err := net.SplitHostPort(addrPart)
		if err != nil {
			log.Printf("❌ 目标地址格式错误 (%s): %v", addrPart, err)
			return
		}
		host = h
		port = p

	} else {
		// 格式: port (兼容旧版，默认访问本地)
		host = "127.0.0.1"
		port = targetStr
		zip = "0"
	}

	// 3. 安全检查：只允许特定端口
	// 防止被用作任意端口扫描工具
	// allowedPorts := map[string]bool{
	// 	"80":   true,
	// 	"8080": true,
	// 	"8588": true,
	// 	"8589": true,
	// 	"8598": true,
	// 	"9089": true,
	// 	"443":  true,
	// 	"9443":  true,
	// }
	// if !allowedPorts[port] {
	// 	log.Printf("❌ 拒绝访问非授权端口: %s", port)
	// 	return
	// }

	// 4. 域名路由逻辑 (核心修改)
	// 根据传入的域名决定连接哪个 IP
	targetHost := "127.0.0.1" // 默认 S1 本地

	// switch host {
	// case "pay.4080517.com":
	// 	// 转发到 S2 (123.56.188.124)
	// 	// 这里可以直接写域名让服务器解析，也可以写死 IP
	// 	targetHost = "pay.4080517.com"
	// case "www.400800517.com", "shop.4080517.com", "localhost", "127.0.0.1":
	// 	// 转发到 S1 本地 (IIS/Nginx)
	// 	targetHost = "127.0.0.1"
	// default:
	// 	// 其他未定义域名，默认回退到本地，或者你可以根据需求放行
	// 	targetHost = "127.0.0.1"
	// }
	switch host {
	case "127.0.0.1", "localhost", "":
		targetHost = "127.0.0.1"
	default:
		targetHost = host
	}
	if port == "" {
		port = "80"
	}

	// 5. 连接目标服务
	targetAddr := net.JoinHostPort(targetHost, port)
	targetConn, err := net.Dial("tcp", targetAddr)
	// targetConn, err := net.DialTimeout("tcp", targetAddr, 10*time.Second)
	if err != nil {
		log.Printf("❌ 隧道连接目标失败 (%s -> %s): %v", targetStr, targetAddr, err)
		return
	}
	defer targetConn.Close()

	// lzm modify 2026-01-08 01:24:45
	// ❌ 已移除 Old StatsStream 包装，改用 copyBuffered
	//
	// // ✅ 修改：使用包装后的流进行传输
	// // wrappedStream := &StatsStream{Stream: s, stats: stats}
	// // 原始流 -> 统计流
	// var transportStream io.ReadWriteCloser = &StatsStream{Stream: s, stats: stats}
	//
	// // === 修改开始：如果启用压缩，再套一层 Snappy 流 ===
	// if zip == "1" {
	// 	// 统计流 -> Snappy流 (解压后发给 targetConn，targetConn 写回的数据压缩后发给统计流)
	// 	transportStream = NewSnappyReadWriteCloser(transportStream)
	// }
	// // === 修改结束 ===
	//
	// // log.Printf("🔗 建立隧道: %s -> %s -> %s", s.Conn().RemotePeer(), targetStr, targetAddr)
	//
	// // 6. 双向转发数据 (TCP 层转发，HTTPS 加密流量透传) (Socket Proxy)
	// // 对于 HTTPS，这里转发的是加密的 TLS 数据流，p2p_proxy 不需要解密
	// go io.Copy(targetConn, transportStream)
	// io.Copy(transportStream, targetConn)
	if zip == "1" {
		// Snappy 情况比较特殊，为了简化，这里先不使用 buffer pool，或者你需要适配 copyBuffered
		// 鉴于 snappy 流本身缓冲，这里暂时维持原样或仅做基础 copy
		// 注意：如果开启压缩，这里需要 SnappyReadWriteCloser

		// lzm modify 2026-01-08 02:08:53
		// Snappy 模式：应用 Buffer Pool 优化内存
		//
		// // 原始流 -> 统计流
		// var transportStream io.ReadWriteCloser = &StatsStream{Stream: s, stats: stats}
		// // 统计流 -> Snappy流 (解压后发给 targetConn，targetConn 写回的数据压缩后发给统计流)
		// transportStream = NewSnappyReadWriteCloser(transportStream)
		// defer transportStream.Close()
		// go io.Copy(targetConn, transportStream)
		// io.Copy(transportStream, targetConn)
		//
		// 直接对 transportStream 使用 copyBuffered，统计解压后/压缩前的流量，减少 StatsStream 堆内存分配
		transportStream := NewSnappyReadWriteCloser(s)

		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			// 从 Source (transportStream/s) 读，写入 Target (targetConn)
			// 注意：copyBuffered 内部会统计流量
			copyBuffered(targetConn, transportStream, stats, false)
			if c, ok := targetConn.(*net.TCPConn); ok {
				c.CloseWrite()
			}
		}()
		go func() {
			defer wg.Done()
			// 从 Target (targetConn) 读，写入 Source (transportStream/s)
			copyBuffered(transportStream, targetConn, stats, true)
			// 必须显式 Close 以 Flush Snappy 缓冲并关闭底层 s
			transportStream.Close()
		}()
		wg.Wait()

	} else {
		// 普通模式：应用 Buffer Pool
		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			// 从 Source (s) 读，写入 Target (targetConn) => Upload/Egress
			// ⚠️ 关键修复：从 reader 读，而不是直接从 s 读，防止 bufio 缓冲区内已读数据被吞掉
			copyBuffered(targetConn, reader, stats, false) // s -> target
			if c, ok := targetConn.(*net.TCPConn); ok {
				c.CloseWrite()
			}
		}()
		go func() {
			defer wg.Done()
			// 从 Target (targetConn) 读，写入 Source (s) => Download/Ingress
			copyBuffered(s, targetConn, stats, true) // target -> s
			s.CloseWrite()
		}()
		wg.Wait()

	}
}

// 处理 p2p_agent 的注册流
func handleRegistration(h host.Host, s network.Stream) {
	defer s.Close()

	// 读取第一行 (身份认证信息)
	reader := bufio.NewReader(s)
	line, err := reader.ReadBytes('\n')
	if err != nil {
		log.Printf("读取注册信息失败: %v", err)
		return
	}

	var meta struct {
		UserID    string   `json:"user_id"`
		ShopID    string   `json:"shopid"`
		ShopName  string   `json:"shopname"`
		Addresses []string `json:"addresses"` // ✅ V8 新增：显式上报的地址
	}
	if err := json.Unmarshal(line, &meta); err != nil {
		log.Printf("解析注册信息失败: %v", err)
		return
	}

	uid := meta.UserID
	sid := meta.ShopID
	sname := meta.ShopName

	if uid == "" || sid == "" {
		log.Printf("注册信息缺失 user_id 或 shopid: %s", string(line))
		return
	}

	// 生成唯一 Key
	key := uid + "_" + sid
	pid := s.Conn().RemotePeer()

	// ✅ V8 新增：同步上报的物理地址到 Peerstore
	if len(meta.Addresses) > 0 {
		var addedCount int
		for _, addrStr := range meta.Addresses {
			ma, err := multiaddr.NewMultiaddr(addrStr)
			if err != nil {
				continue
			}
			// 过滤掉本地回环地址，保留物理/公网地址
			if !strings.Contains(addrStr, "/127.0.0.1") && !strings.Contains(addrStr, "/::1") {
				h.Peerstore().AddAddr(pid, ma, 10*time.Minute)
				addedCount++
			}
		}
		debugLog("📡 [AddrSync] 从客户端 %s 显式学习到 %d 个物理地址", pid.ShortString(), addedCount)
	}

	// ✅ 修改 1: 生成唯一 SessionID
	sessionID := time.Now().UnixNano()
	session := ClientSession{
		PeerID:    pid,
		SessionID: sessionID,
		CmdChan:   make(chan string, 10), // ✅ V12: 指令缓冲通道
	}

	// ✅ 新增：地址自动学习 (Address Learning)
	remoteAddr := s.Conn().RemoteMultiaddr()
	if remoteAddr != nil && !strings.Contains(remoteAddr.String(), "/p2p-circuit") {
		h.Peerstore().AddAddr(pid, remoteAddr, 10*time.Minute)
		debugLog("📡 [AddrLearning] 已学习客户端 %s 的物理地址: %s", pid.ShortString(), remoteAddr)
	}

	stats := getStats(key)
	stats.ShopName = sname

	oldSession, loaded := clientPeers.LoadOrStore(key, session)
	peerClients.Store(pid.String(), key)

	if loaded {
		old := oldSession.(ClientSession)
		if old.SessionID != sessionID {
			log.Printf("🔁 客户端重新连接: [%s] %s", sname, key)
			peerClients.Delete(old.PeerID.String())
			// 关闭指令通道防止内存泄漏 (如果需要)
		} else {
			log.Printf("🔁 客户端重复注册被阻止: [%s] %s", sname, key)
			return
		}
	}

	log.Printf("✅ 客户端上线: [%s] %s (PeerID: %s)", sname, key, pid)

	// === ✅ V12 增强：双向心跳与指令下发协程 ===
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case cmd := <-session.CmdChan:
				// 发送显式指令 (如 "reserve")
				cmdMsg := map[string]string{"cmd": cmd}
				cmdJson, _ := json.Marshal(cmdMsg)
				if _, err := s.Write(append(cmdJson, '\n')); err != nil {
					return
				}
				debugLog("🔔 [Poke] 已下发强制预留指令给: %s", key)
			case <-ticker.C:
				// 发送空 JSON 作为心跳
				if _, err := s.Write([]byte("{}\n")); err != nil {
					return
				}
			}
		}
	}()
	// ========================

	// 保持流打开，直到客户端断开
	// 这样可以感知客户端下线，并防止 p2p_agent 的连接循环报错
	buf := make([]byte, 1024)
	for {
		_, err := s.Read(buf)
		if err != nil {
			log.Printf("❌ 客户端下线: [%s] %s (Session: %d)", sname, key, sessionID)

			// ✅ 修改 4: 安全删除逻辑 (CAS - Compare And Swap 思想)
			// 只有当 map 中存储的 SessionID 与当前连接一致时，才执行删除
			if val, ok := clientPeers.Load(key); ok {
				if val.(ClientSession).SessionID == sessionID {
					clientPeers.Delete(key)
					// 只有主映射被删除了，才清理反向映射
					peerClients.Delete(pid.String())
				} else {
					log.Printf("⚠️ [保留连接] 检测到新会话已建立，跳过删除旧会话数据: %s", key)
				}
			}

			return
		}
	}
}

// 处理 HTTP 代理请求
func handleHttpProxy(ctx context.Context, h host.Host, w http.ResponseWriter, r *http.Request) {
	// === CORS 跨域支持 ===
	//antigravity add 2026-01-23 18:42:55
	// 设置 CORS 响应头，允许跨域请求
	origin := r.Header.Get("Origin")
	if origin != "" {
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Credentials", "true")
	} else {
		w.Header().Set("Access-Control-Allow-Origin", "*")
	}
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept, Origin")
	w.Header().Set("Access-Control-Max-Age", "86400") // 预检请求缓存24小时

	// 处理 OPTIONS 预检请求
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	// === CORS 跨域支持结束 ===

	// ✅ HTTP 层的过载保护与并发限制
	if atomic.LoadInt32(&overloadMode) == 1 {
		http.Error(w, "Server Overloaded", http.StatusServiceUnavailable)
		return
	}
	// HTTP 请求是短连接，如果不涉及维持长连接转发，也可以不占用 Task 配额，
	// 但如果它是主要流量来源，建议加上：
	if !tryAcquireTask() {
		http.Error(w, "Too Many Requests", http.StatusServiceUnavailable)
		return
	}
	defer releaseTask()

	// 1. 解析 URL 参数
	query := r.URL.Query()
	uid := query.Get("user_id")
	sid := query.Get("shopid")
	action := query.Get("a")

	if uid == "" || sid == "" {
		http.Error(w, "Missing user_id or shopid parameters", http.StatusBadRequest)
		return
	}

	// 2. 查找对应的 Peer ID
	key := uid + "_" + sid
	val, ok := clientPeers.Load(key)
	if !ok {
		http.Error(w, fmt.Sprintf("Client %s not connected", key), http.StatusBadGateway)
		return
	}
	// targetPeerID := val.(peer.ID)
	// ✅ 修改: 从结构体提取 PeerID
	targetPeerID := val.(ClientSession).PeerID

	// 3. 检查连接状态
	if h.Network().Connectedness(targetPeerID) != network.Connected {
		clientPeers.Delete(key)
		http.Error(w, "Client connection lost", http.StatusBadGateway)
		return
	}

	// ✅ 修改：获取统计对象
	stats := getStats(key)
	atomic.AddInt32(&stats.Conns, 1)
	atomic.AddInt64(&stats.RequestCount, 1) // ✅ 新增：记录请求次数
	defer atomic.AddInt32(&stats.Conns, -1)

	// === 改动开始：先准备数据，再打开流 ===
	//
	// // 4. 打开一个新的流到 p2p_agent
	// s, err := h.NewStream(ctx, targetPeerID, P2PProtocol)
	// if err != nil {
	// 	log.Printf("打开流失败: %v", err)
	// 	http.Error(w, "Failed to connect to client stream", http.StatusGatewayTimeout)
	// 	return
	// }
	// defer s.Close()
	//
	// // 5. 构造请求数据
	// // 读取 HTTP Body
	// bodyBytes, _ := io.ReadAll(r.Body)
	// var payload map[string]interface{}
	//
	// // 尝试解析 Body 为 JSON，如果为空或失败则创建新 Map
	// if len(bodyBytes) > 0 {
	// 	if err := json.Unmarshal(bodyBytes, &payload); err != nil {
	// 		// 如果 Body 不是 JSON，可能需要处理，这里简单假设是 JSON 或空
	// 		payload = make(map[string]interface{})
	// 	}
	// } else {
	// 	payload = make(map[string]interface{})
	// }
	//
	// // 注入必要的字段 (p2p_agent 需要 action 和 user_id)
	// if action != "" {
	// 	payload["action"] = action
	// }
	// payload["user_id"] = uid
	// payload["shopid"] = sid
	//
	// // 序列化为 JSON 行
	// finalJson, err := json.Marshal(payload)
	// if err != nil {
	// 	http.Error(w, "Failed to marshal request", http.StatusInternalServerError)
	// 	return
	// }
	//
	// // 必须追加换行符，因为 p2p_agent 使用 ReadBytes('\n')
	// finalJson = append(finalJson, '\n')
	//
	// // 6. 发送请求
	// if _, err := s.Write(finalJson); err != nil {
	// 	http.Error(w, "Failed to write to stream", http.StatusBadGateway)
	// 	return
	// }
	//
	// // 7. 读取响应并回写给 HTTP 客户端
	// // p2p_agent 处理完后会关闭 Write 端，io.Copy 会读到 EOF 结束
	// if _, err := io.Copy(w, s); err != nil {
	// 	log.Printf("读取响应失败: %v", err)
	// }

	// lzm modify 2026-01-08 21:06:09
	// // 4. 构造请求数据 (提前处理，防止 p2p_agent 等待超时)
	// bodyBytes, _ := io.ReadAll(r.Body)
	// var payload map[string]interface{}
	//
	// // 尝试解析 Body 为 JSON
	// if len(bodyBytes) > 0 {
	// 	if err := json.Unmarshal(bodyBytes, &payload); err != nil {
	// 		payload = make(map[string]interface{})
	// 	}
	// } else {
	// 	payload = make(map[string]interface{})
	// }
	//
	// // 注入必要的字段
	// if action != "" {
	// 	payload["action"] = action
	// }
	// payload["user_id"] = uid
	// payload["shopid"] = sid
	//
	// // 序列化为 JSON 行
	// finalJson, err := json.Marshal(payload)
	// if err != nil {
	// 	http.Error(w, "Failed to marshal request", http.StatusInternalServerError)
	// 	return
	// }
	// // 必须追加换行符
	// finalJson = append(finalJson, '\n')
	//
	// // 5. 打开一个新的流到 p2p_agent (数据准备好后再连接)
	// s, err := h.NewStream(ctx, targetPeerID, P2PProtocol)
	// if err != nil {
	// 	log.Printf("打开流失败: %v", err)
	// 	http.Error(w, "Failed to connect to client stream", http.StatusGatewayTimeout)
	// 	return
	// }
	// defer s.Close()
	//
	// // lzm modify 2026-01-08 01:31:39
	// //
	// // // ✅ 修改：包装流
	// // wrappedStream := &StatsStream{Stream: s, stats: stats}
	// //
	// // // 6. 发送请求 (立即写入)
	// // if _, err := wrappedStream.Write(finalJson); err != nil {
	// // 	http.Error(w, "Failed to write to stream", http.StatusBadGateway)
	// // 	return
	// // }
	// //
	// // // 7. 读取响应并回写给 HTTP 客户端
	// // if _, err := io.Copy(w, wrappedStream); err != nil {
	// // 	log.Printf("读取响应失败: %v", err)
	// // }
	// // // === 改动结束 ===
	// //
	// // 发送请求
	// if _, err := s.Write(finalJson); err != nil {
	// 	http.Error(w, "Failed to write", http.StatusBadGateway)
	// 	return
	// }
	// // 读取响应 (使用 Buffer Pool)
	// // 因为 w 是 http.ResponseWriter，我们仍然可以用 copyBuffered 从 s 读入 w
	// // Ingress (Download from agent)
	// copyBuffered(w, s, stats, true)
	//
	// 从池中获取 Buffer
	msgBuf := bytesBufferPool.Get().(*bytes.Buffer)
	msgBuf.Reset()
	defer bytesBufferPool.Put(msgBuf)

	// A. 高效读取 Body (自动扩容，复用内部切片)
	_, err := msgBuf.ReadFrom(r.Body)
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}

	// B. 解析 JSON (尽量避免分配，直接操作 Map)
	var payload map[string]interface{}
	if msgBuf.Len() > 0 {
		// 尝试解析，如果 Body 非法或非 JSON，则初始化为空 Map
		if err := json.Unmarshal(msgBuf.Bytes(), &payload); err != nil {
			payload = make(map[string]interface{})
		}
	} else {
		payload = make(map[string]interface{})
	}

	// C. 注入字段
	if action != "" {
		payload["action"] = action
	}
	payload["user_id"] = uid
	payload["shopid"] = sid

	// D. 准备发送数据
	// 重置 Buffer 用于存放即将发送的 JSON
	msgBuf.Reset()

	// 使用 Encoder 直接写入 Buffer，它会自动添加换行符 '\n'
	// 这避免了 json.Marshal 产生新的 []byte 以及 append 的开销
	if err := json.NewEncoder(msgBuf).Encode(payload); err != nil {
		http.Error(w, "Failed to encode request", http.StatusInternalServerError)
		return
	}

	// 4. 打开 P2P 流 (数据准备好后再连接，减少空闲占用)
	s, err := h.NewStream(ctx, targetPeerID, P2PProtocol)
	if err != nil {
		log.Printf("打开流失败: %v", err)
		http.Error(w, "Failed to connect to client stream", http.StatusGatewayTimeout)
		return
	}
	defer s.Close() // 确保流关闭

	// 5. 发送请求 (直接将 Buffer 内容写入流，零拷贝)
	if _, err := msgBuf.WriteTo(s); err != nil {
		http.Error(w, "Failed to write to stream", http.StatusBadGateway)
		return
	}

	// 6. 读取响应
	// 使用现有的 copyBuffered (已优化过)
	if _, err := copyBuffered(w, s, stats, true); err != nil {
		// 此时 Header 可能已写入，无法再写 http.Error，只能记录日志
		log.Printf("读取响应失败: %v", err)
	}

}

// 加载 p2p_proxy 的私钥
func loadAndGeneratorServerBKey() crypto.PrivKey {
	// 如果文件不存在，生成新密钥
	if _, err := os.Stat(BkeyFileName); os.IsNotExist(err) {
		priv, _, err := crypto.GenerateKeyPair(crypto.ECDSA, 256)
		if err != nil {
			log.Fatal(err)
		}
		saveKeyToFile(BkeyFileName, priv)
		return priv
	}

	data, err := os.ReadFile(BkeyFileName)
	if err != nil {
		log.Fatalf("致命错误：无法读取私钥文件: %v", err)
	}

	var versionedKey VersionedKey
	if err := json.Unmarshal(data, &versionedKey); err != nil {
		// 兼容旧格式
		if len(data) > 12 && string(data[:12]) == "LIBP2PKEY-1.0" {
			priv, err := crypto.UnmarshalPrivateKey(data[12:])
			if err != nil {
				log.Fatalf("致命错误：旧版私钥解析失败: %v", err)
			}
			return priv
		}
		log.Fatalf("致命错误：私钥格式错误: %v", err)
	}

	priv, err := crypto.UnmarshalPrivateKey(versionedKey.KeyData)
	if err != nil {
		log.Fatalf("致命错误：私钥解析失败: %v", err)
	}
	return priv
}

func saveKeyToFile(filename string, priv crypto.PrivKey) {
	privBytes, err := crypto.MarshalPrivateKey(priv)
	if err != nil {
		log.Fatal(err)
	}

	versionedKey := VersionedKey{
		Version: 1,
		KeyData: privBytes,
		Magic:   []byte(fmt.Sprintf("LIBP2PKEY-%d.0", 1)),
	}

	data, _ := json.Marshal(versionedKey)
	os.WriteFile(filename, data, 0600)
}

func getExecutableName() string {
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("⚠️ 无法获取可执行文件路径: %v", err)
		return AppName
	}
	return strings.TrimSuffix(filepath.Base(exePath), filepath.Ext(exePath))
}

// === 日志轮转逻辑 ===

// setupLog 初始化日志配置
func setupLog() {
	logDir := "log"
	// 创建日志目录
	_ = os.MkdirAll(logDir, 0755)

	// 创建自定义 Writer
	rotator := &DailyLogWriter{
		Dir:      logDir,
		MaxFiles: 20,
	}

	// 立即初始化当天的文件
	rotator.rotate(time.Now().Format("2006-01-02"))

	// 设置 log 输出：同时写入 控制台(Stdout) 和 文件(rotator)
	log.SetOutput(io.MultiWriter(os.Stdout, rotator))

	// 可选：设置日志格式 (日期 时间 文件:行号)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
}

// ✅ 新增：格式化字节数辅助函数 (B, K, M, G)
func formatBytes(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%dB", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.2f%c", float64(b)/float64(div), "KMGTPE"[exp])
}

// ✅ 新增：统计上报逻辑
func startStatsReporter() {
	// 尝试连接数据库
	db, err := sql.Open("postgres", DbDSN)
	if err != nil {
		log.Printf("⚠️ 无法连接数据库，仅记录日志: %v", err)
	} else {
		// 测试连接
		if err := db.Ping(); err != nil {
			log.Printf("⚠️ 数据库连接失败: %v", err)
			db = nil
		} else {
			log.Printf("✅ 数据库连接成功，统计数据将写入 iserver_common.p2p_proxy_status")
		}
	}

	// 改为 60 秒。减少 IO 和数据库压力。
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()

	exeName := getExecutableName()

	for range ticker.C {
		// 打开日志文件
		// f, err := os.OpenFile("p2p_proxy_status.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		// if err != nil {
		// 	log.Printf("❌ 无法打开统计日志: %v", err)
		// 	continue
		// }

		// ✅ 新增：定义全局汇总变量
		var totalIngress, totalEgress, totalReqs int64
		var totalConns int32

		// 遍历统计 Map
		clientStatsMap.Range(func(k, v any) bool {
			key := k.(string)
			stats := v.(*ClientStats)

			// 原子获取并重置流量计数器 (获取过去5秒的增量)
			in := atomic.SwapInt64(&stats.Ingress, 0)
			out := atomic.SwapInt64(&stats.Egress, 0)
			reqs := atomic.SwapInt64(&stats.RequestCount, 0) // ✅ 新增：获取并重置请求数
			conns := atomic.LoadInt32(&stats.Conns)          // 瞬时值

			// ✅ 新增：累加到全局汇总
			totalIngress += in
			totalEgress += out
			totalReqs += reqs
			totalConns += conns

			// lzm modify 2026-01-08 01:57:25
			// ✅ 修复内存泄漏的核心逻辑：
			// 如果该店铺在过去 60 秒无流量(in/out=0)，无新请求(reqs=0)，且当前无活跃连接(conns=0)
			//
			// // 如果没有任何活动，跳过
			// if in == 0 && out == 0 && conns == 0 && reqs == 0 {
			// 	return true
			// }
			if in == 0 && out == 0 && conns == 0 && reqs == 0 {
				// 再次确认该店铺是否已经断开连接 (不在 clientPeers 中)
				if _, ok := clientPeers.Load(key); !ok {
					// 不在活跃列表中，且无统计数据，安全删除
					clientStatsMap.Delete(key)
				}
				return true // 跳过本次循环的后续写入逻辑
			}

			parts := strings.Split(key, "_")
			if len(parts) < 2 {
				return true
			}
			uid, sid := parts[0], parts[1]

			// ✅ 修改：获取 ShopName 并写入日志
			sname := stats.ShopName
			if sname == "" {
				sname = "-"
			}

			// 1. 写入日志
			// line := fmt.Sprintf("%s | UID:%s SID:%s Name:%s | In:%s Out:%s Reqs:%d Conns:%d\n",
			// 	time.Now().Format(time.RFC3339), uid, sid, sname, formatBytes(in), formatBytes(out), reqs, conns)
			// f.WriteString(line)
			line := fmt.Sprintf("%s | UID:%s SID:%s Name:%s | In:%s Out:%s Reqs:%d Conns:%d\n",
				time.Now().Format(time.RFC3339), uid, sid, sname, formatBytes(in), formatBytes(out), reqs, conns)
			// f.WriteString(line) // 原有写入 (如果不再需要单文件记录可注释或删除)
			writeDailyLog(exeName+"_status", line)

			// 2. 写入数据库
			if db != nil {
				// 假设表结构: created_at, user_id, shop_id, shop_name, upload_bytes, download_bytes, active_conns
				// upload_bytes 对应 Egress (Proxy发给Agent), download_bytes 对应 Ingress (Agent发给Proxy)
				// 或者根据业务定义，这里按 Proxy 视角记录
				// _, err := db.Exec(`
				//     INSERT INTO p2p_proxy_status (created_at, user_id, shop_id, upload_bytes, download_bytes, active_conns)
				//     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
				// 	time.Now(), uid, sid, sname, out, in, conns)
				// if err != nil {
				// 	log.Printf("❌ DB写入失败: %v", err)
				// }
			}

			return true
		})
		// f.Close()

		// ✅ 新增：写入全局汇总日志 p2p_proxy_status_all.log
		line := fmt.Sprintf("%s | TOTAL | In:%s Out:%s Reqs:%d Conns:%d Active:%d\n",
			time.Now().Format(time.RFC3339),
			formatBytes(totalIngress),
			formatBytes(totalEgress),
			totalReqs,
			totalConns,
			activeTaskCount.Load(), // 当前活跃任务数
		)
		writeDailyLog(exeName+"_status_all", line)

	}
}

// === 内存优化 2: 自定义 Copy 函数 ===
// 替代 io.Copy，使用 bufPool 并直接更新 stats，避免创建 StatsStream 包装对象
func copyBuffered(dst io.Writer, src io.Reader, stats *ClientStats, isIngress bool) (written int64, err error) {
	bufPtr := bufPool.Get().(*[]byte)
	defer bufPool.Put(bufPtr)
	buf := *bufPtr

	for {
		nr, er := src.Read(buf)
		if nr > 0 {
			nw, ew := dst.Write(buf[0:nr])
			if nw > 0 {
				written += int64(nw)
				if stats != nil {
					if isIngress {
						atomic.AddInt64(&stats.Ingress, int64(nw))
					} else { // Egress (Payload from proxy out to agent/client)
						atomic.AddInt64(&stats.Egress, int64(nw))
					}
				}
			}
			if ew != nil {
				err = ew
				break
			}
			if nr != nw {
				err = io.ErrShortWrite
				break
			}
		}
		if er != nil {
			if er != io.EOF {
				err = er
			}
			break
		}
	}
	return written, err
}

// NewSnappyReadWriteCloser 改造，使用 s2WriterPool lzm modify 2026-01-08 19:23:08
//
//	func NewSnappyReadWriteCloser(c io.ReadWriteCloser) *SnappyReadWriteCloser {
//		return &SnappyReadWriteCloser{
//			r: snappy.NewReader(c),
//			w: snappy.NewBufferedWriter(c),
//			c: c,
//		}
//	}
//
// 参数 bottom 为底层 io.ReadWriteCloser（通常是 network stream）
func NewSnappyReadWriteCloser(bottom io.ReadWriteCloser) io.ReadWriteCloser {
	// 从池中获取复用的 Reader
	r := acquireS2Reader(bottom)
	// 从池中获取复用的 writer
	w := acquireS2Writer(bottom)
	// 绑定到底层
	return &snappyStream{
		rwc: bottom,
		r:   r,
		w:   w,
	}
}
