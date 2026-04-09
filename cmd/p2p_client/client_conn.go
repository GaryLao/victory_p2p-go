package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	mathrand "math/rand"
	"net"
	"strings"
	"time"
)

// startHostConnector 核心连接逻辑
func startHostConnector(host, port string) {
	addr := net.JoinHostPort(host, port)
	// 初始退避
	baseDelay := 2 * time.Second
	maxDelay := 60 * time.Second
	for {
		// 使用 dialWithFallback 替代 DialTimeout 以支持双栈尝试
		// conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
		conn, err := dialWithFallback(addr, 5*time.Second)
		if err != nil {
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
		go handleServerMessages(conn, stopCh)

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

// handleServerMessages 处理服务端下发的消息
func handleServerMessages(c net.Conn, stopCh chan struct{}) {
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

		// 解析 update JSON
		var um UpdateMessage
		if err := json.Unmarshal([]byte(line), &um); err == nil && um.Action == "update" {
			log.Printf("📨 来自主机：更新通知 version=%s url=%s", um.Version, um.PackageURL)
			go func() {
				info, err := handleUpdate(um, c)
				if err != nil {
					sendUpdateStatus(c, false, "idle", 0, "更新处理失败: "+err.Error())
					log.Printf("❌ 更新处理失败: %v", err)
				} else {
					log.Printf("✅ 更新处理完成: %s", info)
				}
			}()
		} else {
			log.Printf("📨 来自主机: %s", line)
		}
	}
}
