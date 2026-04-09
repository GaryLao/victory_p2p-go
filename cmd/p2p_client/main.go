package main

import (
	"fmt"
	//antigravity modify 2026-01-23 19:48:11
	"io/ioutil" // Go 1.10 兼容性: 使用 ioutil.WriteFile 替代 os.WriteFile
	"log"
	"math/rand"
	"net/http"
	_ "net/http/pprof" // 导入pprof包
	"runtime"
	"time"
)

const (
	AppTitle = "P2P_Client"
	AppName  = "p2p_client"

	AgentClientsidePort = "8386" // p2p_agent 用于监听局域网副机的长连接和心跳
	pprofHttpPort       = "9301" // pprof 监听端口
)

var (
	// 标记是否本机作为“服务器”（SupertouchPCDataIP 指向本机/回环则为 true）
	isLocalServer      bool
	SupertouchPCDataIP string
)

func init() {
	// 修复潜在的随机数问题 (Go 1.10 需要)
	rand.Seed(time.Now().UnixNano())

	log.Printf("🚀 " + AppName + " 启动中...")

	// 优先判断是否运行在“服务器”还是“副机”
	SupertouchPCDataIP = getSupertouchPCDataIP()
	isLocalServer = isLocalIPAddress(SupertouchPCDataIP)

	updatesInProgress = make(map[string]struct{})
	lastAttempt = make(map[string]time.Time)
}

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
			//antigravity modify 2026-01-23 19:48:11
			//os.WriteFile(crashLogFile, []byte(crashContent), 0644)
			ioutil.WriteFile(crashLogFile, []byte(crashContent), 0644)

			log.Printf("💾 崩溃日志已保存到: %s", crashLogFile)
			log.Printf("⚠️ 程序即将退出，请检查日志并修复问题后重新启动")

			// 给日志缓冲区时间写入
			time.Sleep(500 * time.Millisecond)
		}
	}()
	// === 全局 Panic 恢复机制结束 ===

	// 调整内存管理参数
	initMemTuning()

	// 在main函数中启动pprof服务器（可选，调试时使用）
	go func() {
		log.Printf("pprof listening on :%s\n", pprofHttpPort)
		http.ListenAndServe(fmt.Sprintf(":%s", pprofHttpPort), nil)
	}()

	// 1. 初始化日志 (按日保存，保留10个)
	setupLog() // ✅ 新增

	// 仅当不是本机服务器时运行客户端逻辑
	if false == isLocalServer {
		// 单实例运行检查
		checkSingleton()

		// 2. 设置窗口标题 (用于 p2p_monitor 识别)
		setConsoleTitle(AppTitle)

		// 读取配置并启动连接
		startHostConnector(SupertouchPCDataIP, AgentClientsidePort)
	} else {
		log.Printf("ℹ️ 主机不能运行 %s", AppName)
	}
}
