package main

import (
	"bytes"
	"crypto/tls"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/graphql-go/graphql"
	"github.com/klauspost/compress/s2"
)

//	type ClientMeta struct {
//		UserID string
//		ShopID string
//	}
// var (
// 	clientMeta   = make(map[peer.ID]ClientMeta)
// 	clientMetaMu sync.RWMutex
// )

var (
	ADVERSER       = "" // p2p_proxy 地址
	AdverserIp     = ""
	AdverserDomain = ""
	p2pSchema      graphql.Schema

	// 定义一个全局变量用于存储命令行参数
	adverserIPFlag string

	// PostgreSQL 配置覆盖参数
	// 格式: "{name}/{user_id}_{shop_id}/{target_ip}:{target_port}"
	pgTargetFlag string

	// VNC 配置覆盖参数
	// 格式: "{name}/{user_id}_{shop_id}/{target_ip}:{target_port}"
	vncTargetFlag string

	// ✅ 全局变量：标记 p2p_proxy 是否在线
	// isProxyOnline atomic.Bool

	// 标记是否本机作为“服务器”（SupertouchPCDataIP 指向本机/回环则为 true）
	isLocalServer      bool
	SupertouchPCDataIP string

	P2PDebug      = 0
	P2PShowDetail = 0
)

// 新增全局等待表（key = identity + "|" + reqID）
var (
	pendingMu   sync.Mutex
	pendingResp = make(map[string]chan string)
)

// 全局状态标记：用于让监控协程知道“业务层”是否真的通了
var isRegistered atomic.Bool

// 全局副机连接表
var (
	clientMu  sync.RWMutex
	clientMap = make(map[string]*ClientConn) // key = Identity 或 remote 地址
)

// === 内存优化 1: 调整 Go 运行时内存参数 ===

// initMemTuning 调整 Go 运行时内存管理参数以适应低内存环境
func initMemTuning() {
	// 1. 设置软内存限制 (Go 1.19+)
	// 既然限制是 156MB，我们设置保留一点余量，例如 128MB。
	// 这样 Go 运行时会尽全力保持堆内存不超过这个值，甚至牺牲 CPU 进行强力 GC。
	// 这比单纯调 GOGC 更安全。
	// const memLimit = 128 * 1024 * 1024 // 128MB
	memMB := 128 // 默认 128MB
	if v := os.Getenv("P2P_GOMEMLIMIT_MB"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			memMB = n
		}
	}

	// 计算字节限制
	memLimit := int64(memMB) * 1024 * 1024

	debug.SetMemoryLimit(memLimit)

	// 2. 设置 GC 目标百分比 (GOGC)
	// 默认是 100。在小内存机器上，调小这个值可以让 GC 更积极地回收内存，
	// 防止内存占用涨得太高。建议设置为 50 或更低。
	// debug.SetGCPercent(50)
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
	if v := os.Getenv("P2P_SHOW_DETAIL"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			P2PShowDetail = n
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
					// atomic.StoreInt32(&overloadMode, 1)
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
					// atomic.StoreInt32(&overloadMode, 0)
					isOverloaded = false

					// 重置所有策略
					forceGCCooldown = baseCooldown
					ineffectiveGCCount = 0
				}
			}
		}
	}(memLimit)

}

// === 内存优化 2: 复用大 buffer 减少 GC 压力 ===

// 定义一个全局的 buffer pool，复用 32KB 的 slice
var bufPool = sync.Pool{
	New: func() interface{} {
		// 32KB 是 io.Copy 默认的 buffer 大小，适合大流量传输
		// 如果你的包都很小，可以改小一点，比如 4KB，进一步省内存
		b := make([]byte, 32*1024)
		return &b // 存指针可以避免 interface{} 转换时的拷贝
	},
}

// 优化后的数据拷贝函数
// 替代 io.Copy，使用 bufPool 减少 GC 压力
// Agent 版本不需要 stats 统计逻辑
func copyBuffered(dst io.Writer, src io.Reader) (int64, error) {
	// 1. 从 Pool 获取 buffer
	bufPtr := bufPool.Get().(*[]byte)

	// === 关键修改：重置切片长度为最大容量 ===
	// 防止复用的切片长度（len）被其他地方改小了，导致 copy 性能下降或异常
	*bufPtr = (*bufPtr)[:cap(*bufPtr)]

	buf := *bufPtr // 解引用，避免逃逸分析问题

	// 2. 确保函数结束时归还 buffer，哪怕 panic 也能归还
	defer bufPool.Put(bufPtr)

	// 3. 执行拷贝逻辑 (参考 io.CopyBuffer)
	// io.CopyBuffer 会直接使用传入的 buf，不再自己 make
	// io.CopyBuffer 会优先尝试利用 ReadFrom/WriteTo 接口进行零拷贝优化
	return io.CopyBuffer(dst, src, buf)
}

func readRequestBodySafely(w http.ResponseWriter, r *http.Request) ([]byte, error) {
	const maxBodyBytes = int64(10 << 20) // 10MB
	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
	defer r.Body.Close()

	var b bytes.Buffer
	if _, err := copyBuffered(&b, r.Body); err != nil {
		// MaxBytesReader 会返回包含 "request body too large" 的错误信息
		if strings.Contains(err.Error(), "request body too large") || strings.Contains(err.Error(), "http: request body too large") {
			http.Error(w, "request too large", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
		}
		return nil, err
	}
	return b.Bytes(), nil
}

// === 内存优化 3: Snappy 对象池 ===

// --- 旧代码：每次新建 Snappy Reader/Writer ---
// 修改说明：
// 		这是 NewSnappyConn 在每次建立 P2P 流/连接时都创建全新的 Reader 和 Writer（包含内部缓冲区 64KB+）。
// 		由于连接建立频繁（重连守护或多路复用流），这部分会导致大量的内存分配和 GC 压力（即“内存不断增长”的元凶之一）。
//
// // SnappyConn 包装 Snappy 流以适配 net.Conn 接口
// type SnappyConn struct {
// 	net.Conn
// 	r *snappy.Reader
// 	w *snappy.Writer
// }
//
// func NewSnappyConn(c net.Conn) *SnappyConn {
// 	return &SnappyConn{
// 		Conn: c,
// 		r:    snappy.NewReader(c),
// 		w:    snappy.NewBufferedWriter(c),
// 	}
// }
//
// func (s *SnappyConn) Read(p []byte) (int, error) {
// 	return s.r.Read(p)
// }
//
// func (s *SnappyConn) Write(p []byte) (int, error) {
// 	n, err := s.w.Write(p)
// 	if err != nil {
// 		return n, err
// 	}
// 	return n, s.w.Flush() // 必须 Flush 才能发送出去
// }

// --- New 代码：使用对象池复用 Snappy Reader/Writer ---
// 修改说明：
// 		1. 引入 sync.Pool：创建了 snappyReaderPool 和 snappyWriterPool。
// 		2. 重写 NewSnappyConn：不再每次 NewReader/NewBufferedWriter（包含内部缓冲区 64KB+），而是从池中 Get() 并调用 Reset(c) 复用。
// 		3. 实现 Close()：新增了 Close 方法（此前它直接继承 net.Conn 的 Close）。现在它在关闭底层连接前，将 Reader/Writer 归还回池中。

// var (
// 	snappyReaderPool = sync.Pool{
// 		New: func() interface{} {
// 			return snappy.NewReader(nil)
// 		},
// 	}
//
// 	// 修改 snappyWriterPool 的 New 函数
// 	// . NewBufferedWriter，它会在内部额外分配一个输入缓冲区（通常为 64KB），用于积累数据直到凑满一块再压缩。
// 	// . 但 Write 方法中强制 Flush，这实际上绕过了内部缓冲机制，导致这个额外的输入缓冲区仅仅起到了一次内存拷贝的作用，没有带来批量压缩的优势。
// 	// . 使用 NewWriter 替代 NewBufferedWriter， 使得 NewBufferedWriter 的内部缓冲变得多余且浪费内存。
// 	//
// 	snappyWriterPool = sync.Pool{
// 		New: func() interface{} {
// 			return snappy.NewBufferedWriter(nil)
// 		},
// 	}
// )
//
// SnappyConn
// // SnappyConn 包装 Snappy 流以适配 net.Conn 接口
// type SnappyConn struct {
// 	net.Conn
// 	// 为了配合配合上面的 snappyReaderPool 修改，这里也改为 *s2.Reader
// 	r *snappy.Reader
//
// 	// 为了配合配合上面的 snappyWriterPool 修改，这里也改为 *s2.Writer
// 	w *snappy.Writer
// }
//
// func NewSnappyConn(c net.Conn) *SnappyConn {
// 	// 从 Pool 获取 Reader 并重置
// 	// 修改：类型断言更改为 *s2.Reader
// 	r := snappyReaderPool.Get().(*snappy.Reader)
// 	r.Reset(c)
//
// 	// 从 Pool 获取 Writer 并重置
// 	// 修改：类型断言更改为 *s2.Writer
// 	w := snappyWriterPool.Get().(*snappy.Writer)
// 	w.Reset(c)
//
// 	return &SnappyConn{
// 		Conn: c,
// 		r:    r,
// 		w:    w,
// 	}
// }
//
// // Close 覆盖 net.Conn 的 Close 方法，用于归还对象到 Pool
// func (s *SnappyConn) Close() error {
// 	// 归还 Reader
// 	if s.r != nil {
// 		snappyReaderPool.Put(s.r)
//
// 		s.r = nil
// 	}
// 	// 归还 Writer (Writer 可能有缓冲，虽然 Close 是关闭连接，但 Reset 会清理状态)
// 	if s.w != nil {
// 		// 某些版本的 snappy writer 需要 Flush 把缓冲写到底层，
// 		// 但既然连接要关了，底层可能已断。直接 Put 即可，Reset 会处理。
// 		// s.w.Flush()
//
// 		// s2.Writer 归还回池
// 		snappyWriterPool.Put(s.w)
//
// 		s.w = nil
// 	}
//
// 	// 关闭底层连接
// 	return s.Conn.Close()
// }
//
// func (s *SnappyConn) Read(p []byte) (int, error) {
// 	return s.r.Read(p)
// }
//
// func (s *SnappyConn) Write(p []byte) (int, error) {
// 	n, err := s.w.Write(p)
// 	if err != nil {
// 		return n, err
// 	}
// 	// s2.Writer 也需要 Flush 才能确保数据发出
// 	return n, s.w.Flush() // 必须 Flush 才能发送出去
// }

// var (
// 	snappyReaderPool = sync.Pool{
// 		New: func() interface{} {
// 			return getS2Reader(nil) // 使用 s2.Reader 池
// 		},
// 	}
//
// 	snappyWriterPool = sync.Pool{
// 		New: func() interface{} {
// 			return getS2Writer(nil) // 使用 s2.Writer 池
// 		},
// 	}
// )

// // SnappyConn 使用 s2 池（仅展示相关方法）
// type SnappyConn struct {
// 	net.Conn
// 	r  *s2.Reader
// 	w  *s2.Writer
// }
//
// func NewSnappyConn(c net.Conn) *SnappyConn {
// 	return &SnappyConn{
// 		Conn: c,
// 		r:    getS2Reader(c),
// 		w:    getS2Writer(c),
// 	}
// }
//
// func (s *SnappyConn) Close() error {
// 	// 先归还解码器/编码器，再关闭底层连接
// 	if s.r != nil {
// 		putS2Reader(s.r)
// 		s.r = nil
// 	}
// 	if s.w != nil {
// 		_ = putS2Writer(s.w)
// 		s.w = nil
// 	}
// 	return s.Conn.Close()
// }
//
// func (s *SnappyConn) Read(p []byte) (int, error) {
// 	return s.r.Read(p)
// }
// func (s *SnappyConn) Write(p []byte) (int, error) {
// 	n, err := s.w.Write(p)
// 	if err != nil {
// 		return n, err
// 	}
// 	// 确保数据被发出
// 	return n, s.w.Flush()
// }

// --- SnappyConn 改为惰性初始化 reader/writer，避免连接建立时立即分配 ---
// 这样能够把分配推迟到真正的 IO 时，并在 Close 时正确归还
type SnappyConn struct {
	net.Conn
	mu sync.Mutex // 保护 r/w 的懒初始化与归还
	r  *s2.Reader
	w  *s2.Writer
}

func NewSnappyConn(c net.Conn) *SnappyConn {
	return &SnappyConn{Conn: c}
}

// ensureReader 在需要读时才从池中获取并 Reset 到底层连接
func (s *SnappyConn) ensureReader() {
	if s.r != nil {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.r == nil {
		s.r = getS2Reader(s.Conn)
	}
}

// ensureWriter 在需要写时才从池中获取并 Reset 到底层连接
func (s *SnappyConn) ensureWriter() {
	if s.w != nil {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.w == nil {
		s.w = getS2Writer(s.Conn)
	}
}

func (s *SnappyConn) Read(p []byte) (int, error) {
	s.ensureReader()
	return s.r.Read(p)
}

func (s *SnappyConn) Write(p []byte) (int, error) {
	s.ensureWriter()
	n, err := s.w.Write(p)
	if err != nil {
		return n, err
	}
	// 强制 Flush 确保数据发出
	if ferr := s.w.Flush(); ferr != nil {
		// Flush 错误返回给上层（保持原有行为）
		return n, ferr
	}
	return n, nil
}

func (s *SnappyConn) Close() error {
	s.mu.Lock()
	if s.r != nil {
		putS2Reader(s.r) // Reader 通常不需要 Close，直接归还即可
		s.r = nil
	}
	if s.w != nil {
		// 1. 显式 Close 以刷新缓冲区数据写入 s.Conn
		// 即使出错也通常忽略，继续执行后续关闭
		_ = s.w.Close()

		// 2. 归还到池子 (假设 putS2Writer 内部会 Reset)
		_ = putS2Writer(s.w)
		s.w = nil
	}
	s.mu.Unlock()

	// 3. 最后关闭底层连接
	return s.Conn.Close()
}

// === 内存优化 3-1: S2 Reader/Writer 池辅助函数 ===

// // 新增：s2.Reader 池，复用解码器内部状态，避免频繁分配 (~1MB)
// var s2ReaderPool = sync.Pool{
// 	New: func() interface{} {
// 		return s2.NewReader(nil)
// 	},
// }

// 新增：s2.Reader 池
// 优化关键：添加 s2.ReaderMaxBlockSize(64<<10) 选项
// 原因：s2 默认预分配 1MB+ 缓冲区，但 Snappy 协议最大只有 64KB。
// 限制后每个实例内存从 ~1MB 降至 ~64KB。
var s2ReaderPool = sync.Pool{
	New: func() interface{} {
		return s2.NewReader(nil, s2.ReaderMaxBlockSize(64*1024))
	},
}

// 已有的 writer 池（确保使用 Snappy 兼容且未启用 BetterCompression）
var s2WriterPool = sync.Pool{
	New: func() interface{} {
		return s2.NewWriter(nil, s2.WriterSnappyCompat())
	},
}

// 预分配一些对象以避免启动/突发并发时大量 New()
func initS2Pools(prealloc int) {
	for i := 0; i < prealloc; i++ {
		// s2ReaderPool.Put(s2.NewReader(nil))
		// 这里也需要应用 ReaderMaxBlockSize 选项
		s2ReaderPool.Put(s2.NewReader(nil, s2.ReaderMaxBlockSize(64*1024)))

		s2WriterPool.Put(s2.NewWriter(nil, s2.WriterSnappyCompat()))
	}
}

// 获取并重置 reader
func getS2Reader(r io.Reader) *s2.Reader {
	rd := s2ReaderPool.Get().(*s2.Reader)
	rd.Reset(r)
	return rd
}

// 归还 reader，先断开对底层的引用
func putS2Reader(rd *s2.Reader) {
	if rd == nil {
		return
	}
	// Reset(nil) 断开底层引用，避免保持对连接的引用
	// 断开对底层 io.Reader 的引用，避免保留连接/内存
	rd.Reset(nil)
	s2ReaderPool.Put(rd)
}

// 获取并重置 writer
func getS2Writer(w io.Writer) *s2.Writer {
	wr := s2WriterPool.Get().(*s2.Writer)
	wr.Reset(w)
	return wr
}

// 归还 writer，先 Flush，Reset(nil) 再放回池
func putS2Writer(wr *s2.Writer) error {
	if wr == nil {
		return nil
	}
	// 尝试 Flush，忽略网络错误但保证内部缓冲推送
	_ = wr.Flush()
	// 断开底层引用，避免泄露
	// 断开对底层 io.Writer 的引用
	wr.Reset(nil)
	s2WriterPool.Put(wr)
	return nil
}

// === 内存优化 4: TLS 自签证书缓存（避免每次生成） ===

var cachedCert struct {
	sync.Mutex
	cert *tls.Certificate
	ttl  time.Time
}

func getCachedSelfSignedCert() (tls.Certificate, error) {
	cachedCert.Lock()
	defer cachedCert.Unlock()

	// TTL 可根据需要调整
	if cachedCert.cert != nil && time.Now().Before(cachedCert.ttl) {
		return *cachedCert.cert, nil
	}

	// 依赖于项目已有的生成函数：generateSelfSignedCert()
	// 若没有，请用项目内对应实现替代
	cert, err := generateSelfSignedCert()

	if err != nil {
		return tls.Certificate{}, err
	}
	cachedCert.cert = &cert
	cachedCert.ttl = time.Now().Add(6 * time.Hour)
	return cert, nil
}
