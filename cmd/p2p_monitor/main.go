package main

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
	"unsafe"
)

// 定义需要监控的目标
var targets = []struct {
	Title   string // 窗口标题 (必须与 agent/proxy 中设置的一致)
	ExeName string // 可执行文件名
}{
	// {"P2P_Proxy_Server", "p2p_proxy.exe"},
	{"P2P_Agent_Client", "p2p_agent.exe"},
}

func main() {
	setConsoleTitle("P2P_Monitor_Daemon")
	log.Println("🚀 P2P 监控守护进程已启动...")

	// 获取当前程序所在目录
	dir, err := os.Executable()
	if err != nil {
		log.Fatalf("无法获取当前路径: %v", err)
	}
	workDir := filepath.Dir(dir)

	for {
		for _, target := range targets {
			if !isWindowRunning(target.Title) {
				log.Printf("⚠️ 检测到 [%s] 未运行，正在启动...", target.Title)
				startProcess(workDir, target.ExeName)
			}
		}
		// 每 5 秒检测一次
		time.Sleep(5 * time.Second)
	}
}

// 使用 User32.dll 的 FindWindowW 查找窗口
func isWindowRunning(title string) bool {
	user32 := syscall.NewLazyDLL("user32.dll")
	procFindWindow := user32.NewProc("FindWindowW")

	utf16Title, _ := syscall.UTF16PtrFromString(title)

	// FindWindowW(lpClassName, lpWindowName)
	// lpClassName 为 0 (NULL)，表示匹配所有类
	ret, _, _ := procFindWindow.Call(0, uintptr(unsafe.Pointer(utf16Title)))

	// 如果返回值不为 0，说明找到了窗口句柄
	return ret != 0
}

// 启动进程 (使用 cmd /c start 确保弹出新窗口)
func startProcess(workDir, exeName string) {
	exePath := filepath.Join(workDir, exeName)

	// 检查文件是否存在
	if _, err := os.Stat(exePath); os.IsNotExist(err) {
		log.Printf("❌ 找不到文件: %s", exePath)
		return
	}

	// 使用 cmd /c start 命令启动，这样可以为控制台程序打开一个新的窗口
	cmd := exec.Command("cmd", "/c", "start", exeName)
	cmd.Dir = workDir // 设置工作目录

	if err := cmd.Start(); err != nil {
		log.Printf("❌ 启动失败 [%s]: %v", exeName, err)
	} else {
		log.Printf("✅ 已发送启动命令: %s", exeName)
	}
}

func setConsoleTitle(title string) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitle := kernel32.NewProc("SetConsoleTitleW")
	utf16Title, _ := syscall.UTF16PtrFromString(title)
	procSetConsoleTitle.Call(uintptr(unsafe.Pointer(utf16Title)))
}
