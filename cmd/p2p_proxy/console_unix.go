//go:build !windows

package main

const (
	// DbDSN ✅ 新增：数据库连接字符串 (请根据实际环境修改)
	DbDSN = "postgres://sysdba:Masterkey!@127.0.0.1:3433/iserver_common_db?sslmode=disable"
)

func setConsoleTitle(title string) {
	// Linux/Unix 下可以留空或写入日志
}
