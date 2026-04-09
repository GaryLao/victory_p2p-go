package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func startClientManager() {
	// === 副机和主机通用部分开始 ===
	// 启动副机连接监听（单独端口）
	go startClientListener(AgentClientsidePort)

	// 启动 HTTP 接口用于查看在线副机
	//
	// 	http.NewServeMux()：创建并返回一个新的、独立的 *http.ServeMux 实例，
	// 		路由只注册在这个实例上，便于隔离、测试和在同一进程上运行多个不同路由集合。
	// 	http 包的全局行为：http.Handle / http.HandleFunc 会把路由注册到 http.DefaultServeMux（全局变量）；
	// 		http.ListenAndServe(addr, nil) 当第二个参数为 nil 时会使用 http.DefaultServeMux。
	// 	本质上两者使用的类型相同（*http.ServeMux），区别在于是否使用全局默认路由表。
	// 		推荐在可复用/复杂程序中显式创建 NewServeMux() 以避免全局路由污染和测试干扰。
	//
	// go func() {
	// 	http.HandleFunc("/secondaries", clientHandler)
	// 	srv := &http.Server{
	// 		Addr:    ":" + AgentClientHttpPort,
	// 		Handler: nil, // 使用默认 mux
	// 	}
	//
	// 	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
	// 		// 只记录错误，不使用 log.Fatal 以避免退出整个进程
	// 		log.Printf("❌ secondaries HTTP server failed: %v", err)
	// 	}
	// }()
	// 使用独立 ServeMux 注册 /secondaries
	mux := http.NewServeMux()
	mux.HandleFunc("/secondaries", clientHandler)
	mux.HandleFunc("/push_update", pushUpdateHandler)
	mux.HandleFunc("/client_modtime", reqClientModTimeHandler)

	// log.Printf("即将启动 secondaries HTTP 监听 :%s", AgentClientHttpPort)

	// 启动 HTTP 接口用于查看在线副机，指定独立的 mux
	go func() {
		srv := &http.Server{
			Addr:    ":" + AgentClientHttpPort,
			Handler: mux,
		}

		log.Printf("接收副机访问的 HTTP server ListenAndServe 开始 :%s", AgentClientHttpPort)

		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("❌ 接收副机访问的 HTTP server failed: %v", err)
		}
	}()

	// 周期性打印与清理
	go func() {
		// printTicker := time.NewTicker(60 * time.Second)
		// defer printTicker.Stop()

		cleanupTicker := time.NewTicker(30 * time.Second)
		defer cleanupTicker.Stop()

		for {
			select {
			// case <-printTicker.C:
			// 	printClientConns()
			case <-cleanupTicker.C:
				cleanupInactive(cleanupInactiveTimeout) // 超过 2 分钟未心跳则清理
				dedupeClientMapByIdentityPrefix()
			}
		}
	}()

	// 一次性打印并阻塞，真实程序中替换为你的主逻辑
	// printClientConns()

	// === 副机和主机通用部分结束 ===
}

// 启动副机监听服务（在服务端启动）
func startClientListener(port string) {
	ln, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Printf("❌ 副机监听失败（%s）: %v", port, err)
		return
	}
	log.Printf("🔔 副机监听启动，端口: %s", port)

	for {
		conn, err := ln.Accept()
		if err != nil {
			// 临时错误继续循环
			log.Printf("⚠️ Accept error: %v", err)
			continue
		}
		go handleClientConn(conn)
	}
}

func handleClientConn(c net.Conn) {
	remote := c.RemoteAddr().String()

	// 先用短超时读取第一行身份信息，避免被卡住
	_ = c.SetReadDeadline(time.Now().Add(10 * time.Second))
	reader := bufio.NewReader(c)
	idLine, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ 读取副机身份失败 (%s): %v", remote, err)
		if err := c.Close(); err != nil {
			log.Printf("⚠️ 关闭副机连接失败 (%s): %v", remote, err)
		}
		return
	}
	// nameLine, err := reader.ReadString('\n')
	// if err != nil {
	// 	log.Printf("❌ 读取副机门店名称失败 (%s): %v", remote, err)
	// 	c.Close()
	// 	return
	// }
	_ = c.SetReadDeadline(time.Time{}) // 清除超时

	identity := strings.TrimSpace(idLine)
	if identity == "" {
		identity = remote
	}
	// shopName := strings.TrimSpace(nameLine)
	shopName := ""

	sc := &ClientConn{
		Conn:     c,
		Identity: identity,
		Remote:   remote,
		ShopName: shopName,
		LastSeen: time.Now(),
		Online:   true,
		Info:     "",
	}

	// 存入全局表（以 identity 为主键，回退使用 remote）
	key := identity
	if key == "" {
		key = remote
	}
	clientMu.Lock()
	clientMap[key] = sc
	clientMu.Unlock()

	// log.Printf("✅ 副机已连接: [%s] %s (%s)", shopName, key, remote)
	log.Printf("✅ 副机已连接: %s (%s)", key, remote)

	// 读取循环：处理心跳或保持连接（按行）
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			// 连接断开或读取错误，清理并退出
			log.Printf("ℹ️ 副机断开: %s (%v)", remote, err)
			break
		}
		// 更新心跳时间
		clientMu.Lock()
		if cur, ok := clientMap[key]; ok {
			cur.LastSeen = time.Now()
		}
		clientMu.Unlock()

		// 可选：处理心跳内容或命令（这里仅记录）
		msg := strings.TrimSpace(line)
		if msg != "" {
			// if "PING" != msg {
			// 	log.Printf("📨 来自副机 %s: %s", key, msg)
			// }

			// 优先处理心跳
			if msg == "PING" {
				continue
			}

			// 处理 CLIENT_MODTIME 回复，支持两种格式：
			// 1) CLIENT_MODTIME|<reqid>|<modtime>
			// 2) CLIENT_MODTIME|<modtime>  (兼容旧客户端未返回 reqid 的情况)
			if strings.HasPrefix(msg, "CLIENT_MODTIME|") {
				parts := strings.SplitN(msg, "|", 3)
				if len(parts) >= 3 {
					reqID := parts[1]
					modtime := parts[2]
					pendKey := key + "|" + reqID

					pendingMu.Lock()
					if ch, ok := pendingResp[pendKey]; ok {
						select {
						case ch <- modtime:
						default:
						}
						delete(pendingResp, pendKey)
					}
					pendingMu.Unlock()

					log.Printf("ℹ️ 已分发 CLIENT_MODTIME (reqid=%s) -> %s: %s", reqID, key, modtime)
					continue
				}
				// len == 2: 兼容没有 reqid 的客户端，找到第一个匹配 key 的 pending 并返回
				if len(parts) == 2 {
					modtime := parts[1]
					pendingMu.Lock()
					prefix := key + "|"
					for k, ch := range pendingResp {
						if strings.HasPrefix(k, prefix) {
							// 简短说明：这段 Go 代码是一次「非阻塞发送」。
							// 它尝试把一个值发到通道，如果能立即发送则成功；否则走 default 分支（此处为空），不会阻塞，值被丢弃。
							// 典型用途是在不想阻塞读取循环或发送方的情况下尽量快速交付通知，但可能导致消息丢失（如果接收方没有及时读取）。
							// select {
							// case ch <- modtime:
							// default:
							// }
							trySendNonBlocking(ch, modtime)

							delete(pendingResp, k)
							break
						}
					}
					pendingMu.Unlock()

					log.Printf("ℹ️ 已分发 CLIENT_MODTIME (no reqid) -> %s: %s", key, modtime)
					continue
				}
			}

			if strings.HasPrefix(msg, "UPDATE_STATUS|") {
				// 格式示例: UPDATE_STATUS|1|download|45|optional info
				parts := strings.SplitN(msg, "|", 5)
				// parts[0] == "UPDATE_STATUS"
				var working bool
				var task, info string
				var progress int
				if len(parts) > 1 {
					working = parts[1] == "1" || strings.EqualFold(parts[1], "true")
				}
				if len(parts) > 2 {
					task = parts[2]
				}
				if len(parts) > 3 {
					if p, err := strconv.Atoi(parts[3]); err == nil {
						progress = p
					}
				}
				if len(parts) > 4 {
					info = parts[4]
				}

				// 更新 clientMap（并发安全）
				clientMu.Lock()
				if cur, ok := clientMap[key]; ok {
					cur.Working = working
					cur.Task = task
					cur.Progress = progress
					cur.Info = info // 新增：登记 info 到 clientMap
					cur.StatusUpdated = time.Now()
					clientMap[key] = cur
				} else {
					clientMap[key] = &ClientConn{
						Conn:          nil,
						Identity:      key,
						Remote:        remote,
						ShopName:      "",
						LastSeen:      time.Now(),
						Online:        false,
						Working:       working,
						Task:          task,
						Progress:      progress,
						Info:          info, // 新增：登记 info 到 clientMap
						StatusUpdated: time.Now(),
					}
				}
				clientMu.Unlock()

				// 可选：记录 info 日志
				if info != "" {
					log.Printf("ℹ️ 来自 %s 的更新状态: task=%s progress=%d info=%s", key, task, progress, info)
				}
				continue
			}

			// 其他消息继续原有处理（打印或解析 JSON 等）
			log.Printf("📨 来自副机 %s: %s", key, msg)

		}
	}

	// // 清理
	// clientMu.Lock()
	// delete(clientMap, key)
	// clientMu.Unlock()
	// if err := c.Close(); err != nil {
	// 	log.Printf("⚠️ 关闭副机连接失败 (%s): %v", remote, err)
	// }
	// log.Printf("🗑️ 已移除副机连接: %s", key)

	// 将原来的删除逻辑替换为标记离线（保留条目，供 cleanupInactive 后续删除）
	// clientMu.Lock()
	// if cur, ok := clientMap[key]; ok {
	// 	// 标记为离线：清空连接引用，更新 LastSeen（表示最后见面时间）
	// 	cur.Conn = nil
	// 	cur.LastSeen = time.Now()
	// 	cur.Remote = remote
	// 	cur.Online = false
	// 	clientMap[key] = cur
	// } else {
	// 	// 可选：如果条目不存在，创建一个离线占位（确保后续能通过 key 查询到）
	// 	clientMap[key] = &ClientConn{
	// 		Conn:     nil,
	// 		Identity: key,
	// 		Remote:   remote,
	// 		ShopName: "",
	// 		LastSeen: time.Now(),
	// 		Online:   false,
	// 	}
	// }
	// clientMu.Unlock()
	markClientOffline(key, remote)

	if err := c.Close(); err != nil {
		log.Printf("⚠️ 关闭副机连接失败 (%s): %v", remote, err)
	}
	log.Printf("ℹ️ 已标记副机为离线（保留记录）: %s", key)

}

/**
// 示例 1 - 推送到所有在线副机
{
  "targets": [],
  "all": true,
  "package_url": "https://example.com/updates/myapp-v1.2.3.zip",
  "version": "1.2.3",
  "notes": "紧急安全修复"
}

// 示例 2 - 只推送到指定副机（按 Identity）
{
  "targets": ["shop001-0001", "shop002-0002"],
  "all": false,
  "package_url": "https://cdn.example.com/patches/patch-20251224.bin",
  "version": "2025.12.24",
  "notes": "按门店分配的小范围更新"
}

// 示例 3 - 最简请求（只指定下载地址，默认发送到 targets=[] 且 all=false）
{
  "package_url": "http://example.com/updates/latest.pkg"
}
*/

// http://127.0.0.1:9091/push_update
// pushUpdateHandler 接收 POST JSON 请求并将更新消息推送到副机，返回每个目标的发送结果。
func pushUpdateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		// http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		http.Error(w, "不允许的请求方法", http.StatusMethodNotAllowed)
		return
	}

	var req UpdateRequest
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(&req); err != nil {
		// http.Error(w, "Invalid JSON", http.StatusBadRequest)
		http.Error(w, "无效的 JSON", http.StatusBadRequest)
		return
	}

	// 构造推送消息（JSON 行）
	// msgMap := map[string]interface{}{
	// 	"action":      "update",
	// 	"package_url": req.PackageURL,
	// 	"version":     req.Version,
	// 	"notes":       req.Notes,
	// }
	msgMap := UpdateMessage{
		Action:     "update",
		PackageURL: req.PackageURL,
		Version:    req.Version,
		Notes:      req.Notes,
	}
	msgBytes, _ := json.Marshal(msgMap)
	msgBytes = append(msgBytes, '\n')

	// 复制 clientMap 快照，避免在写网络时持锁
	clientMu.RLock()
	snapshot := make(map[string]*ClientConn, len(clientMap))
	for k, v := range clientMap {
		snapshot[k] = v
	}
	clientMu.RUnlock()

	sent := 0
	results := make(map[string]map[string]interface{})

	// helper: 尝试发送并记录结果
	trySend := func(key string, c *ClientConn) {
		if c == nil || c.Conn == nil {
			results[key] = map[string]interface{}{"success": false, "error": "no connection"}
			return
		}
		if err := sendToClient(c, msgBytes); err != nil {
			results[key] = map[string]interface{}{"success": false, "error": err.Error()}
			log.Printf("⚠️ 发送更新到 %s 失败: %v", key, err)
			return
		}
		results[key] = map[string]interface{}{"success": true}
		sent++
	}

	// 辅助：从 "host:port" 或 "ip:port" 中提取 host 部分，出错时返回原样
	hostOf := func(s string) string {
		if s == "" {
			return ""
		}
		if h, _, err := net.SplitHostPort(s); err == nil {
			return h
		}
		return s
	}

	if req.All {
		for key, c := range snapshot {
			trySend(key, c)
		}
	} else {
		// 针对每个指定目标尝试发送，支持按 Identity 或按 Remote 回退查找
		for _, id := range req.Targets {
			id = strings.TrimSpace(id)
			if id == "" {
				continue
			}

			// 1) 精确按 key (完整 identity) 查找
			if c, ok := snapshot[id]; ok {
				trySend(id, c)
				continue
			}

			// 2) 取短 ID（去掉可能的 "|ip" 部分），向所有匹配的 identity 发送（允许重复）
			short := id
			if idx := strings.Index(id, "|"); idx != -1 {
				short = id[:idx]
			}

			matched := 0
			for k, c := range snapshot {
				if k == short || strings.HasPrefix(k, short+"|") {
					trySend(k, c)
					matched++
				}
			}
			if matched > 0 {
				continue
			}

			// 3) 回退按 remote 地址匹配：兼容 id 为 "ip" / "ip:port" 的情况
			found := false
			idHost := hostOf(id)
			for k, c := range snapshot {
				if c == nil || c.Remote == "" {
					continue
				}
				remoteFull := c.Remote           // 通常为 "ip:port"
				remoteHost := hostOf(remoteFull) // 仅主机部分
				// 命中条件：完全相等 ("ip:port")，或主机相等 ("ip")
				if id == remoteFull || idHost == remoteHost {
					trySend(k, c)
					found = true
					// 不 break：如果希望同一个 id 匹配多个连接可去掉 break
					break
				}
			}
			if !found {
				results[id] = map[string]interface{}{"success": false, "error": "not found"}
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]interface{}{
		"status":  "ok",
		"sent":    sent,
		"results": results,
	}
	// json.NewEncoder(w).Encode(resp)
	if err := writeJSON(w, http.StatusOK, resp); err != nil {
		// 可选：额外处理或统计错误（写入已在函数内记录）
	}
}

func reqClientModTimeHandler(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		// http.Error(w, "missing id", http.StatusBadRequest)
		_ = writeJSON(w, http.StatusBadRequest, map[string]interface{}{
			"status": "error",
			"error":  "missing id",
		})
		return
	}

	// 复制 clientMap 快照，避免在写网络时持锁
	clientMu.RLock()
	snapshot := make(map[string]*ClientConn, len(clientMap))
	for k, v := range clientMap {
		snapshot[k] = v
	}
	clientMu.RUnlock()

	// 使用独立函数查找目标连接（支持多种 id 形式）
	key, sc, ok := findClientInSnapshot(snapshot, id)
	if !ok || sc == nil || sc.Conn == nil {
		// http.Error(w, "client not found", http.StatusNotFound)
		_ = writeJSON(w, http.StatusNotFound, map[string]interface{}{
			"status": "error",
			"error":  "client not found",
			"id":     id,
		})
		return
	}

	// 生成请求 ID，注册等待通道
	reqID := strconv.FormatInt(time.Now().UnixNano(), 10)
	pendKey := key + "|" + reqID
	// 为本次请求创建一个用于接收字符串回复的通道，用于接收回复
	// 通道设为缓冲 1 可以在竞态下避免发送方短暂阻塞。
	ch := make(chan string, 1)

	// 然后把它登记到全局的等待表（pendingResp）里
	pendingMu.Lock()
	pendingResp[pendKey] = ch
	pendingMu.Unlock()

	// 发送请求到副机 (格式: REQ_CLIENT_MODTIME|<reqid>\n)
	_, err := sc.Conn.Write([]byte(fmt.Sprintf("REQ_CLIENT_MODTIME|%s\n", reqID)))
	if err != nil {
		// 确保返回前清理注册项（防止泄漏）
		pendingMu.Lock()
		delete(pendingResp, pendKey)
		pendingMu.Unlock()

		// http.Error(w, "write to client failed", http.StatusBadGateway)
		_ = writeJSON(w, http.StatusBadGateway, map[string]interface{}{
			"status": "error",
			"error":  "write to client failed: " + err.Error(),
			"id":     key,
		})
		return
	}

	// // 等待响应或超时
	// select {
	// case resp := <-ch:
	// 	// resp 内容约定为修改时间字符串，例如 "20250101_123456"
	// 	log.Printf("ℹ️ 收到副机 %s 返回的 client.exe 修改时间: %s", key, resp)
	// 	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	// 	w.Write([]byte(resp))
	// case <-time.After(5 * time.Second):
	// 	pendingMu.Lock()
	// 	delete(pendingResp, pendKey)
	// 	pendingMu.Unlock()
	// 	http.Error(w, "timeout waiting client response", http.StatusGatewayTimeout)
	// }
	select {
	case resp := <-ch: // 从通道接收并赋值
		// 尝试清理 pending（读取协程可能已清理，但这里再做一次以防万一）
		pendingMu.Lock()
		delete(pendingResp, pendKey)
		pendingMu.Unlock()

		_ = writeJSON(w, http.StatusOK, map[string]interface{}{
			"status":  "ok",
			"id":      key,
			"modtime": resp,
		})
	case <-time.After(5 * time.Second): // 超时分支
		// 确保返回前清理注册项（防止泄漏）
		pendingMu.Lock()
		delete(pendingResp, pendKey)
		pendingMu.Unlock()

		_ = writeJSON(w, http.StatusGatewayTimeout, map[string]interface{}{
			"status": "error",
			"error":  "timeout waiting client response",
			"id":     key,
		})
	}
}

// findClientInSnapshot 在 snapshot 中按顺序尝试三种匹配方式查找 client：
// 1) 精确 key 匹配
// 2) 短 ID（去掉 "|..."）的前缀匹配（k == short 或 strings.HasPrefix(k, short + "|")）
// 3) 通过 Remote 回退匹配：比对 "ip:port" 或仅主机部分 "ip"
//
// 返回匹配的 key, *ClientConn, true；未找到返回 "", nil, false。
func findClientInSnapshot(snapshot map[string]*ClientConn, id string) (string, *ClientConn, bool) {
	if id == "" {
		return "", nil, false
	}

	// 1) 精确 key
	if c, ok := snapshot[id]; ok {
		return id, c, true
	}

	// 2) 短 ID 或前缀匹配
	short := id
	if idx := strings.Index(id, "|"); idx != -1 {
		short = id[:idx]
	}
	for k, c := range snapshot {
		if k == short || strings.HasPrefix(k, short+"|") {
			return k, c, true
		}
	}

	// 3) 回退按 remote 地址匹配
	idHost := hostOf(id)
	for k, c := range snapshot {
		if c == nil || c.Remote == "" {
			continue
		}
		remoteFull := c.Remote
		remoteHost := hostOf(remoteFull)
		if id == remoteFull || idHost == remoteHost {
			return k, c, true
		}
	}

	return "", nil, false
}

// writeJSON 将 v 编码为 JSON（不开转义 HTML）并一次性写回响应，返回写入或编码错误。
// - 若编码失败，会写入 500 并记录日志。
// - 若写入失败，会记录日志并返回错误。
func writeJSON(w http.ResponseWriter, status int, v interface{}) error {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(v); err != nil {
		// log.Printf("❌ encode response failed: %v", err)
		// http.Error(w, "encode error", http.StatusInternalServerError)
		log.Printf("❌ 编码响应失败: %v", err)
		http.Error(w, "编码错误", http.StatusInternalServerError)

		return err
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if _, err := w.Write(buf.Bytes()); err != nil {
		// log.Printf("❌ write response failed: %v", err)
		log.Printf("❌ 写入响应失败: %v", err)

		return err
	}
	return nil
}

// sendToClient 向指定 ClientConn 写入消息（非阻塞简单实现），返回详细错误并在写后清除 deadline。
func sendToClient(c *ClientConn, msg []byte) error {
	if c == nil || c.Conn == nil {
		// return fmt.Errorf("no connection")
		return fmt.Errorf("无可用连接")
	}

	// 设置写超时并检查错误
	if err := c.Conn.SetWriteDeadline(time.Now().Add(5 * time.Second)); err != nil {
		// return fmt.Errorf("set write deadline: %w", err)
		return fmt.Errorf("设置写超时失败: %w", err)
	}
	// 在函数结束时清除写超时（忽略清除错误）
	defer func() { _ = c.Conn.SetWriteDeadline(time.Time{}) }()

	_, err := c.Conn.Write(msg)
	if err != nil {
		// return fmt.Errorf("write to client failed: %w", err)
		return fmt.Errorf("写入到副机失败: %w", err)
	}
	return nil
}

// hostOf: 从 "host:port" 或 "ip:port" 提取主机部分，出错时返回原样
func hostOf(s string) string {
	if s == "" {
		return ""
	}
	if h, _, err := net.SplitHostPort(s); err == nil {
		return h
	}
	return s
}
