package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/klauspost/compress/s2"
	"github.com/libp2p/go-libp2p/core/peer"
)

// VersionedKey 密钥版本结构 (与 p2p_agent 保持一致)
type VersionedKey struct {
	Version int
	KeyData []byte
	Magic   []byte
}

// ClientSession 包装 PeerID 和 唯一会话ID
type ClientSession struct {
	PeerID    peer.ID
	SessionID int64
	CmdChan   chan string // ✅ V12 新增：指令下发通道 (用于反向唤醒预留)
}

// ClientStats ✅ 新增：客户端统计结构
type ClientStats struct {
	Ingress      int64  // 接收字节数 (Download)
	Egress       int64  // 发送字节数 (Upload)
	Conns        int32  // 当前活跃连接数
	RequestCount int64  // 区间内总请求数 (累计)
	ShopName     string // 存储店铺名称
}

// // StatsStream ✅ 新增：带统计功能的流包装器
// // StatsStream 保留结构定义以兼容旧代码，但建议尽量使用 copyBuffered 直接处理
// type StatsStream struct {
// 	network.Stream
// 	stats *ClientStats
// }
//
// func (s *StatsStream) Read(p []byte) (n int, err error) {
// 	n, err = s.Stream.Read(p)
//
// 	// 注意：如果配合 copyBuffered 使用，这里不要再计数，否则会重复
// 	// 为了兼容性，如果你仍然使用 io.Copy 包装它，请保留。
// 	// 但在本修复方案中，我们将改用 copyBuffered 并不再使用 StatsStream 包装流进行 Copy
// 	//
// 	// if n > 0 && s.stats != nil {
// 	// 	atomic.AddInt64(&s.stats.Ingress, int64(n))
// 	// }
//
// 	return
// }
//
// func (s *StatsStream) Write(p []byte) (n int, err error) {
// 	n, err = s.Stream.Write(p)
// 	if n > 0 && s.stats != nil {
// 		atomic.AddInt64(&s.stats.Egress, int64(n))
// 	}
// 	return
// }

// DailyLogWriter 实现按日轮转的日志写入器
type DailyLogWriter struct {
	Dir      string
	MaxFiles int
	file     *os.File
	date     string
	mu       sync.Mutex
}

// Write 实现 io.Writer 接口
func (w *DailyLogWriter) Write(p []byte) (n int, err error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	// 检查日期是否变更
	today := time.Now().Format("2006-01-02")
	if today != w.date {
		w.rotate(today)
	}

	// 写入文件
	if w.file != nil {
		return w.file.Write(p)
	}
	return len(p), nil
}

// rotate 轮转日志文件
func (w *DailyLogWriter) rotate(today string) {
	// 关闭旧文件
	if w.file != nil {
		w.file.Close()
	}

	// 获取当前可执行文件名前缀 (getExecutableName 已返回无后缀的文件名)
	exeName := getExecutableName()
	// 打开新文件 (追加模式)
	filename := filepath.Join(w.Dir, exeName+"_"+today+".log")
	f, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil {
		w.file = f
		w.date = today
		// 清理旧文件
		w.cleanup()
	} else {
		// 如果打开失败，打印错误到控制台（避免递归调用 log）
		os.Stdout.WriteString(fmt.Sprintf("❌ 无法打开日志文件: %v\n", err))
		w.file = nil
	}
}

// cleanup 清理多余的日志文件
func (w *DailyLogWriter) cleanup() {
	entries, err := os.ReadDir(w.Dir)
	if err != nil {
		return
	}

	// 获取当前可执行文件名前缀 (getExecutableName 已返回无后缀的文件名)
	exeName := getExecutableName()
	prefix := exeName + "_"
	suffix := ".log"

	// 收集符合条件的日志文件
	var logs []string
	for _, e := range entries {
		// if !e.IsDir() && strings.HasPrefix(e.Name(), prefix) && strings.HasSuffix(e.Name(), ".log") {
		// 	logs = append(logs, filepath.Join(w.Dir, e.Name()))
		// }
		if e.IsDir() {
			continue
		}

		name := e.Name()

		// 1. 基础匹配：检查前缀和后缀
		if !strings.HasPrefix(name, prefix) || !strings.HasSuffix(name, suffix) {
			continue
		}

		// 2. 严格匹配：提取中间部分并验证是否为日期格式 (YYYY-MM-DD)
		// 这一步至关重要，防止误删如 p2p_agent_error.log 等非轮转日志
		datePart := name[len(prefix) : len(name)-len(suffix)]
		if _, err := time.Parse("2006-01-02", datePart); err != nil {
			continue
		}

		logs = append(logs, filepath.Join(w.Dir, name))
	}

	// os.ReadDir 返回的文件已按文件名排序 (YYYY-MM-DD 格式天然有序)
	// 如果文件数超过限制，删除最旧的
	if len(logs) > w.MaxFiles {
		removeCount := len(logs) - w.MaxFiles
		for i := 0; i < removeCount; i++ {
			err := os.Remove(logs[i])
			if err != nil {
				os.Stdout.WriteString(fmt.Sprintf("⚠️ 删除旧日志失败: %v\n", err))
			} else {
				os.Stdout.WriteString(fmt.Sprintf("🗑️ 已清理旧日志: %s\n", logs[i]))
			}
		}
	}
}

// snappyStream 是一个简单的包装，用池化的 s2.Writer 做 Write。
// Read 直接委托到底层 io.ReadWriteCloser（如 net stream）。
// 说明：如果你需要对读端做解压（incoming compressed data），应使用 s2.NewReader，并可为 reader 也做池化。
// 这里保持最小改动：当你使用 NewSnappyReadWriteCloser 时，Write 会被压缩并写到底层流。
// 如果协议要求双向压缩/解压，需要增加 s2.Reader 的处理。
type snappyStream struct {
	rwc io.ReadWriteCloser
	r   *s2.Reader
	w   *s2.Writer
}

func (s *snappyStream) Read(p []byte) (int, error) {
	// 读取仍由底层负责（如果对端发回的是压缩数据，这里需要解压器）
	// return s.rwc.Read(p)
	// 从 s.r 读取解压后的数据
	return s.r.Read(p)
}

func (s *snappyStream) Write(p []byte) (int, error) {
	// 写入会被压缩到底层流
	// 写入走 s2.Writer（已 Reset 到底层 writer），注意 s2.Writer.Write 的返回语义
	n, err := s.w.Write(p)
	if err != nil {
		return n, err
	}

	// s2.Writer 可能会缓存，用户必须在 Close 时 Flush
	// return n, err

	// 强制 Flush 确保数据实时发送（对于流式传输很重要）
	return n, s.w.Flush()
}

func (s *snappyStream) Close() error {
	// // 先 Flush 写入器再释放
	// _ = s.w.Flush()
	// releaseS2Writer(s.w)
	// // 关闭底层流
	// return s.rwc.Close()

	// // 先 Flush 写入器并回收到池
	// if s.w != nil {
	// 	_ = s.w.Flush()
	// 	// 避免保留对底层的引用
	// 	s.w.Reset(io.Discard)
	// 	s2WriterPool.Put(s.w)
	// 	s.w = nil
	// }
	// // 关闭底层流（Read 的资源由底层关闭时释放）
	// if s.rwc != nil {
	// 	err := s.rwc.Close()
	// 	s.rwc = nil
	// 	return err
	// }
	// return nil

	var err error
	// 1. 关闭 Writer 并归还
	if s.w != nil {
		// _ = s.w.Flush()
		_ = s.w.Close() // 这一步会 Flush 结尾

		// 释放回池
		releaseS2Writer(s.w)
		s.w = nil
	}
	// 2. 归还 Reader 释放回池
	if s.r != nil {
		releaseS2Reader(s.r)
		s.r = nil
	}
	// 3. 关闭底层连接
	if s.rwc != nil {
		err = s.rwc.Close()
		s.rwc = nil
	}
	return err
}

// // SnappyReadWriteCloser 包装底层连接，支持 Snappy 压缩/解压
//
//	type SnappyReadWriteCloser struct {
//		r *snappy.Reader
//		w *snappy.Writer
//		c io.ReadWriteCloser
//	}
//
//	func (s *SnappyReadWriteCloser) Read(p []byte) (int, error) {
//		return s.r.Read(p)
//	}
//
//	func (s *SnappyReadWriteCloser) Write(p []byte) (int, error) {
//		n, err := s.w.Write(p)
//		if err != nil {
//			return n, err
//		}
//		// 关键：立即刷新缓冲区，否则 HTTP 请求可能会滞留在缓冲区中不发送
//		err = s.w.Flush()
//		return n, err
//	}
//
//	func (s *SnappyReadWriteCloser) Close() error {
//		_ = s.w.Flush()
//		return s.c.Close()
//	}
//
