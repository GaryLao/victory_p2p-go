package main

import (
	"log"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

func getExecutableName() string {
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("⚠️ 无法获取可执行文件路径: %v", err)
		return AppName
	}
	return strings.TrimSuffix(filepath.Base(exePath), filepath.Ext(exePath))
}

func setConsoleTitle(title string) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitle := kernel32.NewProc("SetConsoleTitleW")
	utf16Title, _ := syscall.UTF16PtrFromString(title)
	procSetConsoleTitle.Call(uintptr(unsafe.Pointer(utf16Title)))
}

func checkSingleton() {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procCreateMutex := kernel32.NewProc("CreateMutexW")

	// 定义互斥体名称 (使用 Global 前缀跨会话，或 Local 前缀仅限当前会话)
	// 建议使用 Global 以防止不同用户或服务同时运行
	mutexName := "Global\\P2P_Client_Singleton_Mutex"
	namePtr, _ := syscall.UTF16PtrFromString(mutexName)

	// 调用 CreateMutexW(lpMutexAttributes, bInitialOwner, lpName)
	// 返回值 handle 如果非 0 表示创建成功或获取了已存在的句柄
	handle, _, err := procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(namePtr)))

	// 如果 Global 创建失败（可能是权限问题），尝试降级到 Local
	if handle == 0 {
		mutexName = "Local\\P2P_Client_Singleton_Mutex"
		namePtr, _ = syscall.UTF16PtrFromString(mutexName)
		handle, _, err = procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(namePtr)))
	}

	if handle == 0 {
		log.Printf("⚠️ 无法创建互斥体，无法保证单实例运行: %v", err)
		return
	}

	// 检查错误代码：ERROR_ALREADY_EXISTS = 183
	if err == syscall.Errno(183) {
		log.Printf("⚠️ 程序实例已在运行中，本实例即将退出...")
		time.Sleep(1 * time.Second) // 等待日志写入
		os.Exit(0)
	}

	// 注意：不要调用 CloseHandle(handle)，我们需要让这个句柄在进程生命周期内一直存在。
	// 操作系统会在进程结束时自动释放它。
}

// getClientExeModTime 返回与当前可执行文件同目录下 `client.exe` 的修改时间字符串。
// 找不到或出错时返回空字符串。
func getClientExeModTime() string {
	exePath, err := os.Executable()
	if err != nil {
		return ""
	}
	dir := filepath.Dir(exePath)
	clientPath := filepath.Join(dir, "client.exe")
	fi, err := os.Stat(clientPath)
	if err != nil {
		return ""
	}
	// 使用本地时间，格式为 20060102_150405
	return fi.ModTime().Local().Format("20060102_150405")
}
