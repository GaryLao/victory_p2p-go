package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	mathrand "math/rand"
	"net"
	"os"
	"path/filepath"
	"runtime"       // ✅ 新增：用于调用 GC
	"runtime/debug" // ✅ 新增：用于设置 GC 参数和释放 OS 内存
	"strings"
	"time"
)

const (
	AppTitle = "P2P_Client"
	AppName  = "p2p_client"

	AgentClientsidePort = "8386" // p2p_agent 用于监听局域网副机的长连接和心跳
)

var (
	// 标记是否本机作为“服务器”（SupertouchPCDataIP 指向本机/回环则为 true）
	isLocalServer      bool
	SupertouchPCDataIP string
	// 定义未定义的变量以保持编译通过 (假设在其他文件中定义了这些，如果没有请保留原样)
	updatesInProgress = make(map[string]struct{})
	lastAttempt       = make(map[string]time.Time)
)

func init() {
	log.Printf("🚀 " + AppName + " 启动中...........................................................")

	// 优先判断是否运行在“服务器”还是“副机”
	SupertouchPCDataIP = getSupertouchPCDataIP()
	isLocalServer = isLocalIPAddress(SupertouchPCDataIP)
}

func main() {
	// 1. 初始化日志 (按日保存，保留10个)
	// setupLog() // (假设此函数在你项目其他文件中定义，这里保留调用)

	// ✅✅✅ 新增：启动内存强制管控 ✅✅✅
	setupMemoryManagement()

	if false == isLocalServer {
		// 单实例运行检查
		// checkSingleton() // (假设此函数在其他文件中)

		// 2. 设置窗口标题 (用于 p2p_monitor 识别)
		// setConsoleTitle(AppTitle) // (假设此函数在其他文件中)

		// 读取配置
		startHostConnector(SupertouchPCDataIP, AgentClientsidePort)
	} else {
		log.Printf("ℹ️ 主机不能运行 %s", AppName)
	}
}

// ✅✅✅ 新增：内存管理配置函数 ✅✅✅
// 调参建议：
// 1. debug.SetGCPercent(n):
//    - 默认值 100。
//    - 建议值 20-50。越小 GC 越频繁，内存占用越低，但 CPU 消耗略增。
//    - 设置为 30 对于内存敏感场景是很好的平衡点。
// 2. ticker 时间:
//    - 建议 30s - 120s。
//    - 太短（如 1s）会严重拖慢 CPU。
//    - 太长（如 10m）会导致内存长时间不归还给 OS。
func setupMemoryManagement() {
	// 1. 设置激进的 GC 阈值
	// 告诉 Go Runtime：当新分配的内存达到上次存活内存的 30% 时，就立即触发 GC。
	// (默认是 100%，即内存翻倍才触发)
	debug.SetGCPercent(30)

	// 2. 启动周期性强制释放任务
	go func() {
		// 定义检查周期：30秒
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		for range ticker.C {
			// 强制执行垃圾回收
			runtime.GC()

			// 强制将空闲内存归还给操作系统
			// Go 默认策略很懒，FreeOSMemory 可以强制释放
			debug.FreeOSMemory()

			// 调试日志 (确认生效后可注释掉)
			// log.Printf("🧹 [MemCleanup] 强制 GC 并释放物理内存完成")
		}
	}()
	log.Printf("✅ 内存管理已启动: GOGC=30, 强制回收周期=30s")
}

// dialWithFallback 先尝试 ipv4，再尝试默认协议；使用 net.Dialer 可查看本端地址
func dialWithFallback(addr string, timeout time.Duration) (net.Conn, error) {
	d := &net.Dialer{Timeout: timeout, KeepAlive: 30 * time.Second}
	// 优先尝试 IPv4（在老系统上有时更可靠）
	conn, err := d.Dial("tcp4", addr)
	if err == nil {
		log.Printf("✅ Dial tcp4 成功，本地地址: %v -> %v", conn.LocalAddr(), conn.RemoteAddr())
		return conn, nil
	}
	// 记录第一次错误，便于诊断
	log.Printf("⚠️ tcp4 失败: %v，尝试默认 tcp...", err)
	conn, err = d.Dial("tcp", addr)
	if err == nil {
		log.Printf("✅ Dial tcp 成功，本地地址: %v -> %v", conn.LocalAddr(), conn.RemoteAddr())
	}
	return conn, err
}

// 在 startHostConnector 中把原来的 DialTimeout 替换为 dialWithFallback，
func startHostConnector(host, port string) {
	addr := net.JoinHostPort(host, port)
	// 初始退避
	baseDelay := 2 * time.Second
	maxDelay := 60 * time.Second
	for {
		conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
		if err != nil {
			// 更明确的 jitter 计算（使用 Nanoseconds）
			// jitter := time.Duration(mathrand.Int63n(int64(baseDelay.Nanoseconds()))) * time.Nanosecond
			jitter := time.Duration(mathrand.Int63n(int64(baseDelay)))

			log.Printf("⚠️ 无法连接主机 %s: %v，%v 后重试...", addr, err, baseDelay+jitter)
			time.Sleep(baseDelay + jitter)
			baseDelay *= 2
			if baseDelay > maxDelay {
				baseDelay = maxDelay
			}
			continue
		}

		log.Printf("✅ 已连接到主机: %s", addr)
		// 成功后重置退避
		baseDelay = 2 * time.Second

		// 发送身份信息（user_id|shopid\n）
		shopid := getShopIDFromIni()
		pcid := getPCIDFromIni()
		// ip := getFirstLocalIPv4()
		ip := getAllLocalIPs()
		clientMd := getClientExeModTime()
		// log.Printf("ℹ️ 发送身份: %s-%s|%s|%s", shopid, pcid, ip, clientMd)
		idLine := fmt.Sprintf("%s-%s|%s|%s\n", shopid, pcid, ip, clientMd)
		if _, err := conn.Write([]byte(idLine)); err != nil {
			log.Printf("❌ 发送身份失败: %v", err)
			if err := conn.Close(); err != nil {
				log.Printf("⚠️ 关闭连接失败: %v", err)
			}
			time.Sleep(1 * time.Second)
			continue
		}

		// 启动读取协程，检测主机下发消息或断开
		stopCh := make(chan struct{})
		go func(c net.Conn) {
			defer close(stopCh)
			reader := bufio.NewReader(c)
			for {
				line, err := reader.ReadString('\n')
				if err != nil {
					log.Printf("ℹ️ 主机连接读结束: %v", err)
					return
				}
				line = strings.TrimSpace(line)
				if line == "" {
					continue
				}

				// 按需响应主机请求 client.exe 修改时间
				if strings.HasPrefix(line, "REQ_CLIENT_MODTIME") {
					// 支持格式： REQ_CLIENT_MODTIME 或 REQ_CLIENT_MODTIME|<reqid>
					parts := strings.SplitN(line, "|", 2)
					reqID := ""
					if len(parts) >= 2 {
						reqID = strings.TrimSpace(parts[1])
					}

					mod := getClientExeModTime() // 已存在函数，找不到会返回空字符串
					// 如果有 reqID 就带上，否则也发送兼容格式（保留两段以便 agent 兼容）
					var resp string
					if reqID != "" {
						resp = fmt.Sprintf("CLIENT_MODTIME|%s|%s\n", reqID, mod)
					} else {
						resp = fmt.Sprintf("CLIENT_MODTIME|%s\n", mod)
					}

					log.Printf("ℹ️ 收到主机请求，回复 client.exe 修改时间: %s", mod)
					if _, err := c.Write([]byte(resp)); err != nil {
						log.Printf("❌ 发送 client.exe 修改时间失败: %v", err)
						return
					}
					continue
				}

				// 原有处理逻辑（示例：解析 update JSON 或打印消息）
				var um UpdateMessage
				if err := json.Unmarshal([]byte(line), &um); err == nil && um.Action == "update" {
					log.Printf("📨 来自主机：更新通知 version=%s url=%s", um.Version, um.PackageURL)
					go func() {
						// 假设 handleUpdate 和 sendUpdateStatus 在其他文件中定义
						// info, err := handleUpdate(um, c)
						// if err != nil {
						// 	sendUpdateStatus(c, false, "idle", 0, "更新处理失败: "+err.Error())
						// 	log.Printf("❌ 更新处理失败: %v", err)
						// } else {
						// 	log.Printf("✅ 更新处理完成: %s", info)
						// }
					}()
				} else {
					log.Printf("📨 来自主机: %s", line)
				}
			}
		}(conn)

		// 心跳循环
		heartbeat := time.NewTicker(30 * time.Second)
	loop:
		for {
			select {
			case <-heartbeat.C:
				// 发送心跳（也可发送时间戳或状态）
				_, err := conn.Write([]byte("PING\n"))
				if err != nil {
					log.Printf("❌ 发送心跳失败: %v", err)
					break loop
				}
			case <-stopCh:
				break loop
			}
		}

		heartbeat.Stop()
		if err := conn.Close(); err != nil {
			log.Printf("⚠️ 关闭连接失败: %v", err)
		}
		// 小延迟后重连（避免忙循环）
		time.Sleep(1 * time.Second)
	}
}

// getClientExeModTime 返回与当前可执行文件同目录下 `client.exe` 的修改时间字符串。
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

func getSupertouchPCDataIP() string {
	SystemPara := filepath.Join("Data", "SystemPara.ini")
	return readIniValue(SystemPara, "IP", "SupertouchPCDataIP", "127.0.0.1")
}

func getShopIDFromIni() string {
	SystemPara := filepath.Join("Data", "SystemPara.ini")
	return readIniValue(SystemPara, "Other", "ShopRegisterCode", "001")
}

func getPCIDFromIni() string {
	SystemPara := filepath.Join("Data", "SystemPara.ini")
	return readIniValue(SystemPara, "Other", "CashRegisterCode", "001")
}

func getShopNameFromIni() string {
	SystemPara := filepath.Join("Data", "SystemPara.ini")
	return readIniValue(SystemPara, "PrintCheckString", "KichenTitle2", "")
}

// 新增：判断是否为本机/回环地址
func isLocalIPAddress(ip string) bool {
	if ip == "" || ip == "127.0.0.1" || strings.EqualFold(ip, "localhost") {
		return true
	}
	parsed := net.ParseIP(ip)
	if parsed == nil {
		return false
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return false
	}
	for _, a := range addrs {
		switch v := a.(type) {
		case *net.IPNet:
			if v.IP.Equal(parsed) {
				return true
			}
		case *net.IPAddr:
			if v.IP.Equal(parsed) {
				return true
			}
		}
	}
	return false
}

// 新增函数：获取第一个非回环 IPv4 地址（找不到时返回 127.0.0.1）
func getFirstLocalIPv4() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return "127.0.0.1"
	}
	for _, iface := range interfaces {
		// 跳过不可用或回环接口
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			var ip net.IP
			switch v := a.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			if ipv4 := ip.To4(); ipv4 != nil {
				return ipv4.String()
			}
		}
	}
	return "127.0.0.1"
}

// getAllLocalIPs 返回本机所有非回环、非链路本地的 IP 地址，使用分号分隔。
// 若未找到可用地址，返回 "127.0.0.1"。
func getAllLocalIPs() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return "127.0.0.1"
	}
	var parts []string
	for _, iface := range interfaces {
		// 跳过不可用或回环接口
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			var ip net.IP
			switch v := a.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			// 过滤链路本地地址：IPv4 169.254.x.x，IPv6 fe80::
			if ipv4 := ip.To4(); ipv4 != nil {
				if ipv4[0] == 169 && ipv4[1] == 254 {
					continue
				}
				parts = append(parts, ipv4.String())
			} else {
				s := ip.String()
				if strings.HasPrefix(strings.ToLower(s), "fe80:") {
					continue
				}
				parts = append(parts, s)
			}
		}
	}
	if len(parts) == 0 {
		return "127.0.0.1"
	}
	return strings.Join(parts, ";")
}

// 占位符结构体，防止代码报错
type UpdateMessage struct {
	Action     string
	Version    string
	PackageURL string
}

// 占位符函数，防止代码报错
func setupLog()                                                   {}
func checkSingleton()                                             {}
func setConsoleTitle(title string)                                {}
func handleUpdate(um UpdateMessage, c net.Conn) (string, error)   { return "", nil }
func sendUpdateStatus(c net.Conn, b bool, s string, i int, e string) {}
func readIniValue(file, section, key, def string) string          { return def }