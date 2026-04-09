//go:build windows

package main

import (
	"syscall"
	"unsafe"
)

const (
	// DbDSN ✅ 新增：数据库连接字符串 (请根据实际环境修改)
	DbDSN = "postgres://sysdba:Masterkey!@yippee001.pg.rds.aliyuncs.com:3433/iserver_common_db?sslmode=disable"
)

// 新增：设置控制台标题的辅助函数
func setConsoleTitle(title string) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitle := kernel32.NewProc("SetConsoleTitleW")
	utf16Title, _ := syscall.UTF16PtrFromString(title)
	procSetConsoleTitle.Call(uintptr(unsafe.Pointer(utf16Title)))
}
