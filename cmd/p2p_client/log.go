package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

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
	filename := filepath.Join(w.Dir, exeName+"_"+today+".log")
	// 打开新文件 (追加模式)
	f, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil {
		w.file = f
		w.date = today

		// lzm modify 2026-01-08 18:45:05
		// // 清理旧文件
		// w.cleanup()
		//
		// 异步清理旧日志，避免在持锁/写路径中做耗时 IO
		go func(dir, exe string, maxFiles int) {
			cleanupOldLogs(dir, exe, maxFiles)
		}(w.Dir, exeName, w.MaxFiles)
	} else {
		// 如果打开失败，打印错误到控制台（避免递归调用 log）
		os.Stdout.WriteString(fmt.Sprintf("❌ 无法打开日志文件: %v\n", err))
		w.file = nil
	}
}

// 新增：不持锁的清理函数，可被并发安全地调用
func cleanupOldLogs(dir, exeName string, maxFiles int) {
	entries, err := ioutil.ReadDir(dir)
	if err != nil {
		return
	}

	prefix := exeName + "_"
	suffix := ".log"

	var logs []string
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		if !strings.HasPrefix(name, prefix) || !strings.HasSuffix(name, suffix) {
			continue
		}
		datePart := name[len(prefix) : len(name)-len(suffix)]
		if _, err := time.Parse("2006-01-02", datePart); err != nil {
			continue
		}
		logs = append(logs, filepath.Join(dir, name))
	}

	// 保持按文件名（日期）排序（os.ReadDir 已按名称排序），删除最旧的多余文件
	if len(logs) > maxFiles {
		removeCount := len(logs) - maxFiles
		for i := 0; i < removeCount; i++ {
			if err := os.Remove(logs[i]); err != nil {
				os.Stdout.WriteString("⚠️ 删除旧日志失败: " + err.Error() + "\n")
			} else {
				os.Stdout.WriteString("🗑️ 已清理旧日志: " + logs[i] + "\n")
			}
		}
	}
}

// // cleanup 清理多余的日志文件
// func (w *DailyLogWriter) cleanup() {
// 	entries, err := ioutil.ReadDir(w.Dir)
// 	if err != nil {
// 		return
// 	}
//
// 	// 获取当前可执行文件名前缀 (getExecutableName 已返回无后缀的文件名)
// 	exeName := getExecutableName()
// 	prefix := exeName + "_"
// 	suffix := ".log"
//
// 	// 收集符合条件的日志文件
// 	var logs []string
// 	for _, e := range entries {
// 		// if !e.IsDir() && strings.HasPrefix(e.Name(), prefix) && strings.HasSuffix(e.Name(), ".log") {
// 		// 	logs = append(logs, filepath.Join(w.Dir, e.Name()))
// 		// }
// 		if e.IsDir() {
// 			continue
// 		}
//
// 		name := e.Name()
//
// 		// 1. 基础匹配：检查前缀和后缀
// 		if !strings.HasPrefix(name, prefix) || !strings.HasSuffix(name, suffix) {
// 			continue
// 		}
//
// 		// 2. 严格匹配：提取中间部分并验证是否为日期格式 (YYYY-MM-DD)
// 		// 这一步至关重要，防止误删如 p2p_agent_error.log 等非轮转日志
// 		datePart := name[len(prefix) : len(name)-len(suffix)]
// 		if _, err := time.Parse("2006-01-02", datePart); err != nil {
// 			continue
// 		}
//
// 		logs = append(logs, filepath.Join(w.Dir, name))
// 	}
//
// 	// os.ReadDir 返回的文件已按文件名排序 (YYYY-MM-DD 格式天然有序)
// 	// 如果文件数超过限制，删除最旧的
// 	if len(logs) > w.MaxFiles {
// 		removeCount := len(logs) - w.MaxFiles
// 		for i := 0; i < removeCount; i++ {
// 			err := os.Remove(logs[i])
// 			if err != nil {
// 				os.Stdout.WriteString(fmt.Sprintf("⚠️ 删除旧日志失败: %v\n", err))
// 			} else {
// 				os.Stdout.WriteString(fmt.Sprintf("🗑️ 已清理旧日志: %s\n", logs[i]))
// 			}
// 		}
// 	}
// }
