package main

import (
	"log"
	"net"
	"strings"
	"time"
)

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

// isLocalIPAddress 判断是否为本机/回环地址
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

// getFirstLocalIPv4 获取第一个非回环 IPv4 地址（找不到时返回 127.0.0.1）
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
