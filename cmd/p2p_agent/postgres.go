package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/peerstore"
	"github.com/libp2p/go-libp2p/core/protocol"
	"github.com/multiformats/go-multiaddr"
)

// formatPgTargetAddr 格式化目标地址
// 兼容旧版：当端口为 5432（默认端口）时只发送 IP，否则发送 IP:Port
// 这样旧版接收端能正常工作（使用本地配置的端口）
func formatPgTargetAddr(ip string, port int) string {
	if ip == "" {
		ip = "127.0.0.1"
	}
	if port == 0 || port == 5432 {
		// 默认端口，只发送 IP（兼容旧版）
		return ip + "\n"
	}
	// 非默认端口，发送 IP:Port（新版格式）
	return fmt.Sprintf("%s:%d\n", ip, port)
}

// ✅ 新增：加载配置文件并启动本地监听
func startPgProxyServices(ctx context.Context, h host.Host, serverBID peer.ID) {
	configFile := "pg_proxysvr.json"
	data, err := os.ReadFile(configFile)
	if err != nil {
		if os.IsNotExist(err) {
			log.Printf("[PgProxy] 配置文件 %s 不存在，跳过启动", configFile)
			return
		}
		log.Printf("[PgProxy] 读取配置失败: %v", err)
		return
	}

	var config PgProxyConfig
	if err := json.Unmarshal(data, &config); err != nil {
		log.Printf("[PgProxy] 解析配置失败: %v", err)
		return
	}

	for _, mapping := range config.Mappings {
		go func(m PgProxyItem) {
			addr := fmt.Sprintf("0.0.0.0:%d", m.LocalPort)
			listener, err := net.Listen("tcp", addr)
			if err != nil {
				log.Printf("❌ [PgProxy] 监听本地端口失败 %d: %v", m.LocalPort, err)
				return
			}
			log.Printf("🚀 [PgProxy] 启动监听: :%d -> Proxy -> %s:%d (zip=%d, %s)",
				m.LocalPort, m.TargetIP, m.TargetPort, m.EnableZip, m.Comment)

			for {
				conn, err := listener.Accept()
				if err != nil {
					log.Printf("❌ [PgProxy] Accept error: %v", err)
					time.Sleep(time.Second)
					continue
				}

				// 处理单个连接
				go handlePgClientConn(ctx, h, serverBID, conn, m)
			}
		}(mapping)
	}
}

// ✅ 新增：处理 pgadmin 的本地连接并转发给 Proxy
func handlePgClientConn(ctx context.Context, h host.Host, serverBID peer.ID, localConn net.Conn, mapping PgProxyItem) {
	defer localConn.Close()

	// 1. 连接到 Proxy 节点 (使用 PostgresTunnelProtocol)
	// 注意：确保这里的 PostgresTunnelProtocol 与 proxy 端定义的一致，通常是 "/p2p_proxy/tunnel/1.0.0"
	s, err := h.NewStream(ctx, serverBID, protocol.ID(PostgresTunnelProtocol))
	if err != nil {
		log.Printf("❌ [PgProxy] 无法连接到 Proxy 节点: %v", err)
		return
	}
	defer s.Close()

	// 2. 发送目标地址协议头
	// 格式遵循 handleTunnel 定义: "host:port\n" 或 "host:port|zip\n"
	targetStr := fmt.Sprintf("%s:%d|%d\n", mapping.TargetIP, mapping.TargetPort, mapping.EnableZip)
	_, err = s.Write([]byte(targetStr))
	if err != nil {
		log.Printf("❌ [PgProxy] 发送握手信息失败: %v", err)
		return
	}

	log.Printf("🔗 [PgProxy] 新连接: 本地 %s -> :%d -> %s:%d (zip=%d)",
		localConn.RemoteAddr(), mapping.LocalPort, mapping.TargetIP, mapping.TargetPort, mapping.EnableZip)

	// 使用 Snappy 包装 P2P 流，实现透明压缩
	// 注意：确保 NewSnappyConn/NewSnappyReadWriteCloser 已正确定义并可用
	var transport io.ReadWriteCloser = s
	if mapping.EnableZip == 1 {
		rawConn := &StreamConn{s}
		transport = NewSnappyConn(rawConn)
		// 确保 snappy 缓冲被刷新并关闭 (主线程退出时的最后保障)
		defer transport.Close()
	}

	// 3. 双向数据拷贝
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		// 本地 -> Proxy (Read localConn -> Compress -> Write s)
		io.Copy(transport, localConn)

		// 🔴 关键修复：处理 Snappy 缓冲残留问题
		// Snappy Writer 带有缓冲，io.Copy 结束后数据可能还在内存中。
		// 必须触发 Flush 动作将数据推送到网络层。

		// 1. 尝试使用 CloseWrite 接口 (最推荐：你的 Snappy 包装器应该实现此接口：先 Flush Writer，再调底层的 CloseWrite)
		if cw, ok := transport.(interface{ CloseWrite() error }); ok {
			cw.CloseWrite()
		} else {
			// 2. 如果没有 CloseWrite，尝试检测是否实现了 Flush 接口
			type Flusher interface {
				Flush() error
			}
			if f, ok := transport.(Flusher); ok {
				f.Flush()
			}

			// 3. 只有在确保数据 Flush 后，才尝试关闭底层流的写端，通知对端 EOF
			// 下面这个操作假设 transport 内部的 writer 已经被上面的操作刷新了，
			// 否则直接关闭 s 会导致缓冲数据丢失。
			/*
				if streamer, ok := s.(interface{ CloseWrite() error }); ok {
					streamer.CloseWrite()
				}
			*/
		}
	}()

	go func() {
		defer wg.Done()
		// Proxy -> 本地 (Read s -> Decompress -> Write localConn)
		io.Copy(localConn, transport)
		if tcpConn, ok := localConn.(*net.TCPConn); ok {
			tcpConn.CloseWrite()
		}
	}()

	wg.Wait()

	log.Printf("🏁 [PgProxy] 连接断开: %d", mapping.LocalPort)
}

// 新增：被控端处理 -> 连接本地 PostgreSQL (5432)
func handlePostgresConnection(s network.Stream) {
	defer s.Close()
	log.Printf("📥 收到 PostgreSQL 远程连接请求")

	reader := bufio.NewReader(s)

	// ✅ 优化超时策略：
	// 1. 握手阶段 (读取目标IP)：设置 5秒 超时，防止恶意连接或网络假死导致协程泄漏
	s.SetReadDeadline(time.Now().Add(5 * time.Second))
	addrLine, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ 读取PG目标信息失败: %v", err)
		return
	}
	// 2. 数据传输阶段：清除超时，允许长连接和空闲挂起
	s.SetReadDeadline(time.Time{})
	s.SetWriteDeadline(time.Time{})

	// 解析目标地址，支持 IP:Port 格式
	targetAddr := strings.TrimSpace(addrLine)
	var targetIP, port string
	if strings.Contains(targetAddr, ":") {
		// 格式: IP:Port
		parts := strings.SplitN(targetAddr, ":", 2)
		targetIP = parts[0]
		port = parts[1]
	} else {
		// 仅 IP，使用本地配置的端口
		targetIP = targetAddr
		port = getPostgresPortFromConf()
	}
	if targetIP == "" {
		targetIP = "127.0.0.1"
	}
	if port == "" {
		port = "5432"
	}

	// 连接本地 PostgreSQL
	pgConn, err := net.Dial("tcp", targetIP+":"+port)
	if err != nil {
		log.Printf("❌ 无法连接本地 PostgreSQL (%s:%s): %v", targetIP, port, err)
		return
	}
	defer pgConn.Close()

	// 替换为更高效的copyBuffered
	// 双向转发数据
	// 注意：不能简单使用 io.Copy，因为需要同时处理双向数据流
	//
	// go io.Copy(pgConn, s)
	// io.Copy(s, pgConn)
	//

	var wg sync.WaitGroup
	wg.Add(2)

	// 从 s 读，写入 pgConn（上传 / egress）
	go func() {
		defer wg.Done()
		// ✅ 新增：过滤心跳包，防止转发到PostgreSQL
		buf := make([]byte, 32*1024)
		for {
			n, err := reader.Read(buf)
			if err != nil {
				if err != io.EOF {
					log.Printf("⚠️ 读取VNC/PG流错误: %v", err)
				}
				break
			}
			// 转发正常数据
			if _, err := pgConn.Write(buf[:n]); err != nil {
				log.Printf("⚠️ 写入PG连接错误: %v", err)
				break
			}
		}
		if c, ok := pgConn.(interface{ CloseWrite() error }); ok {
			_ = c.CloseWrite()
		}
	}()

	// 从 pgConn 读，写入 s（下载 / ingress）
	go func() {
		defer wg.Done()
		if _, err := copyBuffered(s, pgConn); err != nil && err != io.EOF {
			log.Printf("ℹ️ PG连接已断开: %v", err)
		}
		if c, ok := s.(interface{ CloseWrite() error }); ok {
			_ = c.CloseWrite()
		}
	}()

	wg.Wait()
}

// 新增：控制端处理 -> 启动本地监听 -> 转发给 Proxy (PG Relay)
func startPostgresClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", localPort))
	if err != nil {
		log.Printf("❌ PG 客户端监听失败 (端口 %d): %v", localPort, err)
		return
	}
	log.Printf("🐘 PG 中继启动: 本地 :%d -> 远程 %s_%s -> %s:%d", localPort, targetUser, targetShop, targetIP, targetPort)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("PG Accept error: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			// 1. 连接 Proxy (使用 PG Relay 协议)
			s, err := h.NewStream(ctx, proxyPID, protocol.ID(PostgresRelayProtocol))
			if err != nil {
				log.Printf("❌ 连接 Proxy 失败: %v", err)
				return
			}
			defer s.Close()

			// 2. 发送目标信息
			targetInfo := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
			if _, err := s.Write([]byte(targetInfo)); err != nil {
				log.Printf("❌ [Postgres] 发送目标信息失败: %v", err)
				return
			}

			// 3. 发送目标服务器的IP地址和端口
			// 兼容旧版：端口为 5432 时只发送 IP
			postgresAddr := formatPgTargetAddr(targetIP, targetPort)
			if _, err := s.Write([]byte(postgresAddr)); err != nil {
				log.Printf("❌ [Postgres] 发送目标地址失败: %v", err)
				return
			}

			log.Printf("✅ [PG] 隧道建立成功，开始转发数据 (Mode: Relay)")

			// 3. 双向转发
			// 替换为更高效的 copyBuffered
			// 双向转发数据
			// 注意：不能简单使用 io.Copy，因为需要同时处理双向数据流
			//
			// go io.Copy(s, c)
			// io.Copy(c, s)
			//
			// 使用 copyBuffered 替换原来的 io.Copy 双向转发
			var wg sync.WaitGroup
			wg.Add(2)

			// 从本地连接 c -> 远端流 s
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(s, c); err != nil && err != io.EOF {
					log.Printf("⚠️ copy local->remote error: %v", err)
				}
				// 尝试半关闭远端写端以触发对端 EOF（如果支持）
				if cw, ok := s.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			// 从远端流 s -> 本地连接 c
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, s); err != nil && err != io.EOF {
					log.Printf("⚠️ copy remote->local error: %v", err)
				}
				// 尝试半关闭本地写端（如果支持）
				if cw, ok := c.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			wg.Wait()

		}(conn)
	}
}

func startPostgresP2PClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ PG 客户端监听失败 (端口 %d): %v", localPort, err)
		return
	}
	defer listener.Close()

	log.Printf("🐘 PG 监听启动: 本地 :%d -> 远程 %s_%s -> %s:%d (P2P)", localPort, targetUser, targetShop, targetIP, targetPort)

	// 缓存目标 PeerID，用于快速重连
	var cachedTargetPeerID peer.ID

	for {
		// 接受本地 VNC Viewer 的连接
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("❌ [PG] Accept 错误: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			var targetPeerID peer.ID
			useCached := false

			// 1. 检查是否可以复用现有连接 (快速路径)
			// 如果我们知道目标是谁，且底层连接是 Connected 状态，直接跳过打洞
			if cachedTargetPeerID != "" && h.Network().Connectedness(cachedTargetPeerID) == network.Connected {
				targetPeerID = cachedTargetPeerID
				useCached = true
				log.Printf("⚡ [PG] 复用现有 P2P 连接: %s", targetPeerID.ShortString())
			} else {
				// 2. 慢速路径：向 Proxy 查询目标信息并打洞
				// 1. 向 Proxy 查询目标 Peer 信息
				infoStream, err := h.NewStream(ctx, proxyPID, protocol.ID(PostgresPeerInfoProtocol))
				if err != nil {
					log.Printf("❌ [PG] 连接 Proxy 失败: %v", err)
					return
				}

				// 1.发送目标信息头 (User|Shop\n)
				header := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
				if _, err := infoStream.Write([]byte(header)); err != nil {
					log.Printf("❌ [PG] 发送目标头失败: %v", err)
					infoStream.Close()
					return
				}

				var resp struct {
					PeerID string   `json:"peer_id"`
					Addrs  []string `json:"addrs"`
				}
				if err := json.NewDecoder(infoStream).Decode(&resp); err != nil {
					log.Printf("❌ [PG] 解析目标信息失败: %v", err)
					infoStream.Close()
					return
				}
				infoStream.Close()

				pid, err := peer.Decode(resp.PeerID)
				if err != nil {
					log.Printf("❌ [PG] 无效的 PeerID: %v", err)
					return
				}
				targetPeerID = pid

				// 2. 尝试 P2P 直连 (Hole Punching)
				log.Printf("🔍 [PG] 尝试 P2P 打洞连接目标 <%s> (地址数: %d)...", targetPeerID.ShortString(), len(resp.Addrs))

				var addrInfos []multiaddr.Multiaddr
				for _, addrStr := range resp.Addrs {
					if ma, err := multiaddr.NewMultiaddr(addrStr); err == nil {
						addrInfos = append(addrInfos, ma)
					}
				}

				if len(addrInfos) > 0 {
					h.Peerstore().AddAddrs(targetPeerID, addrInfos, peerstore.TempAddrTTL)
				}

				// 显式连接，带超时 (稍微增加超时时间)
				ctxConnect, cancel := context.WithTimeout(ctx, 8*time.Second)
				if err := h.Connect(ctxConnect, peer.AddrInfo{ID: targetPeerID}); err != nil {
					log.Printf("⚠️ [PG] P2P 连接尝试失败 (将尝试通过 Relay): %v", err)
					// 不返回，继续尝试 NewStream，Libp2p 会自动寻找路径
				} else {
					log.Printf("🚀 [PG] P2P 直连成功")
				}
				cancel()

				// 更新缓存
				cachedTargetPeerID = targetPeerID
			}

			// 3. 打开数据流
			s, err := h.NewStream(ctx, targetPeerID, protocol.ID(PostgresTargetProtocol))
			if err != nil {
				log.Printf("❌ [PG] 打开数据流失败: %v", err)
				// 如果复用失败（例如连接假死），清除缓存，下次强制重连
				if useCached {
					cachedTargetPeerID = ""
				}
				return
			}
			defer s.Close()

			// 2. 发送目标服务器的IP地址和端口
			// 兼容旧版：端口为 5432 时只发送 IP
			pgAddr := formatPgTargetAddr(targetIP, targetPort)
			if _, err := s.Write([]byte(pgAddr)); err != nil {
				log.Printf("❌ [PG] 发送目标地址失败: %v", err)
				s.Reset()
				return
			}

			log.Printf("✅ [PG] 通道建立成功，开始转发数据")

			// 4. 双向数据转发 (稳健模式)
			// var wg sync.WaitGroup
			// wg.Add(2)
			//
			// // Viewer -> P2P Agent
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(s, c)
			// 	s.CloseWrite() // 告诉远程 Agent 我们发完了
			// }()
			//
			// // P2P Agent -> Viewer
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(c, s)
			// 	// 尝试关闭本地 TCP 的写端，触发 Viewer 的 EOF
			// 	if tcpConn, ok := c.(*net.TCPConn); ok {
			// 		_ = tcpConn.CloseWrite()
			// 	} else {
			// 		_ = c.Close()
			// 	}
			// }()
			//
			// wg.Wait()
			//
			// 双向转发，使用 copyBuffered 复用全局 bufPool
			var wg sync.WaitGroup
			wg.Add(2)

			// Viewer -> P2P Agent
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(s, c); err != nil && err != io.EOF {
					log.Printf("⚠️ copy viewer->agent error: %v", err)
				}
				// 尝试半关闭 P2P 流
				if cw, ok := s.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			// P2P Agent -> Viewer
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, s); err != nil && err != io.EOF {
					log.Printf("⚠️ copy agent->viewer error: %v", err)
				}
				// 尝试关闭本地 TCP 的写端
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				} else if cw, ok := c.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			wg.Wait()

		}(conn)
	}
}
func startPostgresP2PRelayClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ PG 混合中继监听失败 (端口 %d): %v", localPort, err)
		return
	}
	defer listener.Close()

	log.Printf("🐘 PG 混合中继启动: 本地 :%d -> 远程 %s_%s -> %s:%d (P2P/Relay)", localPort, targetUser, targetShop, targetIP, targetPort)

	// ✅ 新增：缓存目标 PeerID，避免每次连接都查询 Proxy
	var cachedPeerID peer.ID
	var cachedPeerIDMu sync.RWMutex

	// ✅ 新增：标记 P2P 打洞是否已失败过（失败一次后永久跳过打洞）
	var p2pFailed bool
	var p2pFailedMu sync.RWMutex

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("❌ [PG] Accept 错误: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			var targetStream network.Stream
			var targetPeerID peer.ID
			connMode := "Relay" // 默认为中继模式

			// ✅ 优化：优先尝试使用缓存的 PeerID 快速建立连接
			cachedPeerIDMu.RLock()
			useCached := cachedPeerID != ""
			if useCached {
				targetPeerID = cachedPeerID
			}
			cachedPeerIDMu.RUnlock()

			// 快速路径：如果有缓存且连接仍然有效，直接创建流
			if useCached && h.Network().Connectedness(targetPeerID) == network.Connected {
				p2pStreamCtx, cancelP2P := context.WithTimeout(ctx, 5*time.Second)
				s, streamErr := h.NewStream(p2pStreamCtx, targetPeerID, protocol.ID(PostgresTargetProtocol))
				cancelP2P()
				if streamErr == nil {
					log.Printf("⚡ [PG] 复用 P2P 连接成功")
					connMode = "P2P"
					targetStream = s
					// 发送目标地址（兼容旧版）
					pgAddr := formatPgTargetAddr(targetIP, targetPort)
					if _, err := s.Write([]byte(pgAddr)); err != nil {
						s.Close()
						targetStream = nil
					}
				}
			}

			// ✅ 检查是否已经标记 P2P 失败，如果是则直接跳过所有 P2P 尝试
			p2pFailedMu.RLock()
			skipAllP2P := p2pFailed
			p2pFailedMu.RUnlock()

			// 慢速路径：只有当 P2P 未失败时才尝试查询和打洞
			if targetStream == nil && !skipAllP2P {
				infoCtx, cancelInfo := context.WithTimeout(ctx, 10*time.Second)
				targetInfo, err := fetchPostgresPeerInfo(infoCtx, h, proxyPID, targetUser, targetShop)
				cancelInfo()

				if err == nil {
					targetPeerID = targetInfo.ID

					// 更新缓存
					cachedPeerIDMu.Lock()
					cachedPeerID = targetPeerID
					cachedPeerIDMu.Unlock()

					if h.Network().Connectedness(targetPeerID) != network.Connected {
						log.Printf("🔍 [PG] 尝试 P2P 打洞连接目标 %s...", targetPeerID.ShortString())
						h.Peerstore().AddAddrs(targetPeerID, targetInfo.Addrs, peerstore.TempAddrTTL)
						connCtx, cancelConn := context.WithTimeout(ctx, 30*time.Second)
						_ = h.Connect(connCtx, *targetInfo)
						cancelConn()
					}

					if h.Network().Connectedness(targetPeerID) == network.Connected {
						p2pStreamCtx, cancelP2P := context.WithTimeout(ctx, 30*time.Second)
						s, streamErr := h.NewStream(p2pStreamCtx, targetPeerID, protocol.ID(PostgresTargetProtocol))
						cancelP2P()
						if streamErr == nil {
							log.Printf("🚀 [PG] P2P 直连成功")
							connMode = "P2P"
							targetStream = s
							// 发送目标地址（兼容旧版）
							pgAddr := formatPgTargetAddr(targetIP, targetPort)
							if _, err := s.Write([]byte(pgAddr)); err != nil {
								s.Close()
								targetStream = nil
							}
						}
					}
				}
			}

			// 2. 如果 P2P 失败，切换到中继模式
			if targetStream == nil {
				// ✅ 标记 P2P 打洞失败，后续连接直接使用中继
				p2pFailedMu.Lock()
				if !p2pFailed {
					p2pFailed = true
					log.Printf("⚠️ [PG] P2P 不可用，已标记后续连接直接使用中继模式")
				}
				p2pFailedMu.Unlock()

				log.Printf("🔄 [PG] 切换中继模式...")
				s, err := h.NewStream(ctx, proxyPID, protocol.ID(PostgresRelayProtocol))
				if err != nil {
					log.Printf("❌ [PG] 中继连接失败: %v", err)
					return
				}
				header := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
				if _, err := s.Write([]byte(header)); err != nil {
					s.Close()
					return
				}
				// 发送目标地址（兼容旧版）
				pgAddr := formatPgTargetAddr(targetIP, targetPort)
				if _, err := s.Write([]byte(pgAddr)); err != nil {
					s.Close()
					return
				}
				targetStream = s
			}

			log.Printf("✅ [PG] 隧道建立成功，开始转发数据 (Mode: %s)", connMode)

			var wg sync.WaitGroup
			wg.Add(2)
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(targetStream, c); err != nil && err != io.EOF {
					log.Printf("⚠️ PG copy local->remote error: %v", err)
				}
				if cw, ok := targetStream.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, targetStream); err != nil && err != io.EOF {
					log.Printf("⚠️ PG copy remote->local error: %v", err)
				}
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				}
			}()
			wg.Wait()

			targetStream.Close()
		}(conn)
	}
}

func fetchPostgresPeerInfo(ctx context.Context, h host.Host, proxyPID peer.ID, tUser, tShop string) (*peer.AddrInfo, error) {
	s, err := h.NewStream(ctx, proxyPID, protocol.ID(PostgresPeerInfoProtocol))
	if err != nil {
		return nil, err
	}
	defer s.Close()

	header := fmt.Sprintf("%s|%s\n", tUser, tShop)
	if _, err := s.Write([]byte(header)); err != nil {
		return nil, err
	}

	reader := bufio.NewReader(s)
	line, err := reader.ReadBytes('\n')
	if err != nil {
		return nil, err
	}

	lineStr := string(line)
	if len(lineStr) >= 3 && lineStr[:3] == "ERR" {
		return nil, fmt.Errorf("remote error: %s", lineStr)
	}

	var resp struct {
		PeerID string   `json:"peer_id"`
		Addrs  []string `json:"addrs"`
	}
	if err := json.Unmarshal(line, &resp); err != nil {
		return nil, err
	}

	targetID, err := peer.Decode(resp.PeerID)
	if err != nil {
		return nil, err
	}

	info := &peer.AddrInfo{ID: targetID}
	for _, addrStr := range resp.Addrs {
		if madder, err := multiaddr.NewMultiaddr(addrStr); err == nil {
			info.Addrs = append(info.Addrs, madder)
		}
	}
	return info, nil
}
