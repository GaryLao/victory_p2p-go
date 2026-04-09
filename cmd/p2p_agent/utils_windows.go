package main

import (
	"log"
	"os"
	"syscall"
	"time"
	"unsafe"
)

// === 新增：单实例检查函数 ===
func checkSingleton() {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procCreateMutex := kernel32.NewProc("CreateMutexW")

	// 定义互斥体名称 (使用 Global 前缀跨会话，或 Local 前缀仅限当前会话)
	// 建议使用 Global 以防止不同用户或服务同时运行
	mutexName := "Global\\P2P_Agent_Singleton_Mutex"
	namePtr, _ := syscall.UTF16PtrFromString(mutexName)

	// 调用 CreateMutexW(lpMutexAttributes, bInitialOwner, lpName)
	// 返回值 handle 如果非 0 表示创建成功或获取了已存在的句柄
	handle, _, err := procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(namePtr)))

	// 如果 Global 创建失败（可能是权限问题），尝试降级到 Local
	if handle == 0 {
		mutexName = "Local\\P2P_Agent_Singleton_Mutex"
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

// 新增：设置控制台标题的辅助函数
func setConsoleTitle(title string) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitle := kernel32.NewProc("SetConsoleTitleW")
	utf16Title, _ := syscall.UTF16PtrFromString(title)
	procSetConsoleTitle.Call(uintptr(unsafe.Pointer(utf16Title)))
}
