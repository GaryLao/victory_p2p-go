package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
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

// formatVncTargetAddr 格式化目标地址
// 兼容旧版：当端口为 8900（默认端口）或 0 时只发送 IP，否则发送 IP:Port
func formatVncTargetAddr(ip string, port int) string {
	if ip == "" {
		ip = "127.0.0.1"
	}
	if port == 0 || port == 8900 {
		return ip + "\n"
	}
	return fmt.Sprintf("%s:%d\n", ip, port)
}

// handleVNCConnection 被控端处理：接收 P2P 请求 -> 转发给本地 UltraVNC (8900)
func handleVNCConnection(s network.Stream) {
	defer s.Close()
	log.Printf("📥 收到 VNC 远程连接请求")

	reader := bufio.NewReader(s)

	// // 1. 读取第一行获取目标身份信息 (user_id|shopid\n)
	// header, err := reader.ReadString('\n')
	// if err != nil {
	// 	log.Printf("❌ 读取VNC目标身份信息失败: %v", err)
	// 	return
	// }
	// log.Printf("🎯 目标身份信息: %s", strings.TrimSpace(header))
	// // 注意：此处读取到的身份信息未被进一步使用，但必须读取以消耗缓冲区内容

	// 2. 读取第二行获取目标IP地址（如果提供了的话）
	s.SetReadDeadline(time.Now().Add(5 * time.Second))
	ipLine, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ 读取VNC目标信息失败: %v", err)
		return
	}
	s.SetReadDeadline(time.Time{}) // 清除超时

	targetInfo := strings.TrimSpace(ipLine)
	log.Printf("🔍 目标 VNC 信息: %s", targetInfo)

	var targetIP string
	port := getVNCPortFromIni()

	// 检查是否包含端口 (IP:Port)
	if idx := strings.LastIndex(targetInfo, ":"); idx > 0 {
		targetIP = targetInfo[:idx]
		port = targetInfo[idx+1:] // 使用发送过来的端口
	} else {
		targetIP = targetInfo
	}

	if targetIP == "" {
		targetIP = "127.0.0.1" // 默认值
	}

	vncTarget := targetIP + ":" + port

	// // 连接本地 VNC Server
	// // 确保 UltraVNC Server 正在运行且监听 8900
	// vncConn, err := net.Dial("tcp", "127.0.0.1:"+port, 5*time.Second)
	// if err != nil {
	// 	log.Printf("❌ 无法连接本地 VNC Server (%s): %v", port, err)
	// 	return
	// }
	// defer vncConn.Close()
	//
	// // 双向转发
	// go io.Copy(vncConn, s)
	// io.Copy(s, vncConn)

	// 设置超时，防止卡死
	conn, err := net.DialTimeout("tcp", vncTarget, 5*time.Second)
	if err != nil {
		log.Printf("❌ [Target] 无法连接本地 VNC 服务 (%s): %v", vncTarget, err)
		return
	}
	defer conn.Close()

	log.Printf("✅ [Target] VNC 隧道已建立: P2P -> %s", vncTarget)

	// 双向数据转发
	// var wg sync.WaitGroup
	// wg.Add(2)
	//
	// go func() {
	// 	defer wg.Done()
	// 	io.Copy(conn, s) // P2P -> Local VNC
	// 	if tcpConn, ok := conn.(*net.TCPConn); ok {
	// 		tcpConn.CloseWrite()
	// 	}
	// }()
	//
	// go func() {
	// 	defer wg.Done()
	// 	io.Copy(s, conn) // Local VNC -> P2P
	// 	s.CloseWrite()
	// }()
	//
	// wg.Wait()
	//
	// 双向转发，使用全局 bufPool 提供的 copyBuffered
	var wg sync.WaitGroup
	wg.Add(2)

	// P2P -> 本地 VNC
	go func() {
		defer wg.Done()
		// ⚠️ 关键修复：使用 reader 而不是 s，防止 bufio 缓冲区内的数据丢失
		if _, err := copyBuffered(conn, reader); err != nil && err != io.EOF {
			log.Printf("ℹ️ VNC连接已断开 (p2p->vnc): %v", err)
		}
		// 半关闭本地写端，通知 VNC 对端 EOF
		if tcpConn, ok := conn.(*net.TCPConn); ok {
			_ = tcpConn.CloseWrite()
		} else if cw, ok := conn.(interface{ CloseWrite() error }); ok {
			_ = cw.CloseWrite()
		}
	}()

	// 本地 VNC -> P2P
	go func() {
		defer wg.Done()
		if _, err := copyBuffered(s, conn); err != nil && err != io.EOF {
			log.Printf("ℹ️ VNC连接已断开 (vnc->p2p): %v", err)
		}
		// 半关闭 P2P 写端，通知对端 EOF（s 通常支持 CloseWrite）
		if cw, ok := s.(interface{ CloseWrite() error }); ok {
			_ = cw.CloseWrite()
		}
	}()

	wg.Wait()

	// log.Printf("👋 [Target] VNC 会话结束")

}

// startVNCClient [稳定版] 纯中继模式
// 逻辑：本地监听 -> 连接 Proxy (VNCRelayProtocol) -> 告诉 Proxy 目标是谁 -> Proxy 转发给目标
// 优点：极其稳定，无视 NAT 类型，连接建立速度快（无需打洞等待）
// startVNCClient [稳定版] 纯中继模式
// 逻辑：本地监听 -> 连接 Proxy (VNCRelayProtocol) -> 告诉 Proxy 目标是谁 -> Proxy 转发给目标
// 优点：极其稳定，无视 NAT 类型，连接建立速度快（无需打洞等待）
func startVNCClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ [VNC] 启动监听失败 (端口 %d): %v", localPort, err)
		return
	}
	defer listener.Close()

	log.Printf("🚀 [VNC] 中继模式启动: %d -> Proxy -> 目标 %s_%s", localPort, targetUser, targetShop)

	for {
		// 接受本地 VNC Viewer 的连接
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("❌ [VNC] Accept 错误: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			log.Printf("📥 [VNC] 收到连接请求，正在通过 Proxy 建立隧道...")

			// 连接到 Proxy 的 VNC 中继服务
			// 对应 p2p_proxy 中的 VNCRelayProtocol = "/p2p_proxy/vnc_relay/1.0.0"
			stream, err := h.NewStream(ctx, proxyPID, protocol.ID(VNCRelayProtocol))
			if err != nil {
				log.Printf("❌ [VNC] 连接 Proxy 失败: %v", err)
				return
			}
			defer stream.Close()

			// 1. 发送目标身份信息 (格式: user_id|shopid\n)
			// Proxy 的 handleVNCRelay 会读取这一行来决定连谁
			targetInfo := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
			if _, err := stream.Write([]byte(targetInfo)); err != nil {
				log.Printf("❌ [VNC] 发送目标信息失败: %v", err)
				return
			}

			// 2. 发送目标VNC服务器的IP地址和端口
			// 兼容旧版：端口为 8900 时只发送 IP
			vncAddr := formatVncTargetAddr(targetIP, targetPort)
			if _, err := stream.Write([]byte(vncAddr)); err != nil {
				log.Printf("❌ [VNC] 发送目标地址失败: %v", err)
				return
			}

			log.Printf("✅ [VNC] 隧道建立成功，开始转发数据 (Relay Mode)")

			// 4. 双向数据转发 (使用 WaitGroup 确保双向都关闭)
			// var wg sync.WaitGroup
			// wg.Add(2)
			//
			// // 本地 Viewer -> Proxy
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(stream, c)
			// 	// 告诉 Proxy 我发完了 (关闭写端)
			// 	stream.CloseWrite()
			// }()
			//
			// // Proxy -> 本地 Viewer
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(c, stream)
			// 	// 收到 Proxy 的 EOF，关闭本地连接
			// 	// c.Close() // defer 会处理
			// }()
			//
			// wg.Wait()
			//
			var wg sync.WaitGroup
			wg.Add(2)

			// 本地 Viewer -> Proxy
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(stream, c); err != nil && err != io.EOF {
					log.Printf("⚠️ copy viewer->proxy error: %v", err)
				}
				// 尝试对远端（stream）做半关闭，通知对端 EOF（如果支持 CloseWrite）
				if cw, ok := stream.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			// Proxy -> 本地 Viewer
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, stream); err != nil && err != io.EOF {
					log.Printf("⚠️ copy proxy->viewer error: %v", err)
				}
				// 尝试对本地连接做半关闭（通常是 *net.TCPConn）
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				} else if cw, ok := c.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			wg.Wait()

			log.Printf("👋 [VNC] 会话结束")

		}(conn)
	}
}

// startVNCP2PRelayClient ✅ 修复版：顺序模式 (P2P -> Relay)
// 彻底解决"竞速模式"导致的双重连接和 VNC Server 封禁问题
// startVNCP2PRelayClient ✅ 修复版：顺序模式 (P2P -> Relay)
// 彻底解决"竞速模式"导致的双重连接和 VNC Server 封禁问题
func startVNCP2PRelayClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	ln, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ VNC 监听失败: %v", err)
		return
	}
	log.Printf("🖥️ VNC_客户端启动: %s -> 目标 %s_%s (顺序模式: P2P[2s]->Relay)", listenAddr, targetUser, targetShop)

	for {
		localConn, err := ln.Accept()
		if err != nil {
			log.Printf("❌ Accept 失败: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			var targetStream network.Stream

			// =============================================================
			// 步骤 1: 尝试 P2P (设置极短超时，快速失败)
			// =============================================================

			// 1.1 向 Proxy 查询目标 P2P 地址 (限时 2秒)
			infoCtx, cancelInfo := context.WithTimeout(ctx, 10*time.Second)
			targetInfo, err := fetchVNCPeerInfo(infoCtx, h, proxyPID, targetUser, targetShop, targetIP)
			cancelInfo()

			if err != nil {
				log.Printf("⚠️ [VNC] 获取目标 P2P 信息失败: %v", err)
			} else {
				// 1.2 尝试建立底层连接 (如果尚未连接)
				if h.Network().Connectedness(targetInfo.ID) != network.Connected {
					var addrList []string
					for _, a := range targetInfo.Addrs {
						addrList = append(addrList, a.String())
					}
					log.Printf("🔍 [VNC] 尝试 P2P 打洞连接目标 %s (地址数: %d, 地址: %v)...", targetInfo.ID.ShortString(), len(targetInfo.Addrs), addrList)

					// / 💡 修改：将超时时间从 10秒 增加到 30秒
					// NAT 打洞涉及中继协商和多次握手，10秒在某些环境下可能不足
					connCtx, cancelConn := context.WithTimeout(ctx, 30*time.Second)

					// 💡 优化：将获取到的地址添加到 Peerstore，增加 libp2p 内部打洞的成功率
					h.Peerstore().AddAddrs(targetInfo.ID, targetInfo.Addrs, peerstore.TempAddrTTL)

					if connErr := h.Connect(connCtx, *targetInfo); connErr != nil {
						// 即使超时，也不要立即放弃，有时连接可能在后台刚刚建立完成
						log.Printf("⚠️ [VNC] P2P 底层连接尝试结束: %v", connErr)
					}
					cancelConn()
				}

				// 1.3 如果连接成功，尝试打开流
				if h.Network().Connectedness(targetInfo.ID) == network.Connected {
					// / 💡 优化：为 P2P 流建立设置明确的超时 (30秒)
					p2pStreamCtx, cancelP2P := context.WithTimeout(ctx, 30*time.Second)
					s, streamErr := h.NewStream(p2pStreamCtx, targetInfo.ID, protocol.ID(VNCTargetProtocol))
					cancelP2P()

					if streamErr == nil {
						log.Printf("🚀 [VNC] P2P 直连成功")
						targetStream = s

						// 2. 发送目标VNC服务器的IP地址和端口（仅在流建立成功后执行，防止空指针崩溃）
						// 兼容旧版：端口为 8900 时只发送 IP
						vncAddr := formatVncTargetAddr(targetIP, targetPort)
						// 注意：s.Write 在此处是安全的，因为此时 streamErr == nil 且 s != nil
						if _, err := s.Write([]byte(vncAddr)); err != nil {
							log.Printf("❌ [VNC] 发送目标地址失败: %v", err)
							s.Close()
							targetStream = nil // 确保下方会回退到中继模式
						}
					} else {
						// 这里是流建立失败的关键日志 (例如协议不匹配或打洞未及时完成)
						log.Printf("⚠️ [VNC] P2P 流建立失败: %v", streamErr)
					}
				} else {
					log.Printf("⚠️ [VNC] P2P 最终未连接，无法打开流")
				}
			}

			// =============================================================
			// 步骤 2: 如果 P2P 失败，立即降级到 Relay (中继)
			// =============================================================
			connMode := "P2P"
			if targetStream == nil {
				connMode = "Relay"
				log.Printf("🔄 [VNC] P2P 不可用，切换中继模式...")
				s, err := h.NewStream(ctx, proxyPID, protocol.ID(VNCRelayProtocol))
				if err != nil {
					log.Printf("❌ [VNC] 中继连接失败: %v", err)
					return
				}

				// 1.发送目标信息头 (User|Shop\n)
				header := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
				if _, err := s.Write([]byte(header)); err != nil {
					log.Printf("❌ [VNC] 发送目标头失败: %v", err)
					s.Close()
					return
				}

				// 2. 发送目标VNC服务器的IP地址和端口
				// 兼容旧版：端口为 8900 时只发送 IP
				vncAddr := formatVncTargetAddr(targetIP, targetPort)
				if _, err := s.Write([]byte(vncAddr)); err != nil {
					log.Printf("❌ [VNC] 发送目标地址失败: %v", err)
					s.Close()
					return
				}

				targetStream = s
			}

			log.Printf("✅ [VNC] 隧道建立成功，开始转发数据 (Mode: %s)", connMode)

			// =============================================================
			// 步骤 3: 双向数据转发
			// =============================================================

			// defer targetStream.Close()
			//
			// // 使用 io.Copy 进行双向转发
			// go io.Copy(targetStream, c)
			// io.Copy(c, targetStream)

			// 4. 双向数据转发 (使用 WaitGroup 确保双向都关闭)
			// var wg sync.WaitGroup
			// wg.Add(2)
			//
			// // 本地 Viewer -> Proxy
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(targetStream, c)
			// 	// 告诉 Proxy 我发完了 (关闭写端)
			// 	if cw, ok := targetStream.(interface{ CloseWrite() error }); ok {
			// 		cw.CloseWrite()
			// 	}
			// }()
			//
			// // Proxy -> 本地 Viewer
			// go func() {
			// 	defer wg.Done()
			// 	_, _ = io.Copy(c, targetStream)
			// 	// 收到 Proxy 的 EOF，关闭本地连接
			// 	// c.Close() // defer 会处理
			// 	if tcpConn, ok := c.(*net.TCPConn); ok {
			// 		tcpConn.CloseWrite()
			// 	}
			// }()
			//
			// wg.Wait()

			var wg sync.WaitGroup
			wg.Add(2)

			// 本地 Viewer -> Target (P2P or Relay)
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(targetStream, c); err != nil && err != io.EOF {
					log.Printf("⚠️ copy viewer->server error: %v", err)
				}
				// 尝试对远端做半关闭
				if cw, ok := targetStream.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			// Target -> 本地 Viewer
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, targetStream); err != nil && err != io.EOF {
					log.Printf("⚠️ copy server->viewer error: %v", err)
				}
				// 尝试对本地连接做半关闭
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				} else if cw, ok := c.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			wg.Wait()

			log.Printf("👋 [VNC] 会话结束")

		}(localConn)
	}
}

// startVNCP2PClient 控制端处理：启动本地监听 -> 优先尝试 P2P 直连
// 优化：复用 P2P 连接，避免每次重连都进行打洞
// startVNCP2PClient 控制端处理：启动本地监听 -> 优先尝试 P2P 直连
// 优化：复用 P2P 连接，避免每次重连都进行打洞
func startVNCP2PClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string, targetPort int) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ [VNC] 无法启动本地监听: %v", err)
		return
	}
	defer listener.Close()

	log.Printf("🖥️ VNC_客户端启动: %s -> 目标 %s_%s (P2P)", listenAddr, targetUser, targetShop)

	// 缓存目标 PeerID，用于快速重连
	var cachedTargetPeerID peer.ID

	for {
		// 接受本地 VNC Viewer 的连接
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("❌ [VNC] Accept 错误: %v", err)
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
				log.Printf("⚡ [VNC] 复用现有 P2P 连接: %s", targetPeerID.ShortString())
			} else {
				// 2. 慢速路径：向 Proxy 查询目标信息并打洞
				// 1. 向 Proxy 查询目标 Peer 信息
				infoStream, err := h.NewStream(ctx, proxyPID, protocol.ID(VNCPeerInfoProtocol))
				if err != nil {
					log.Printf("❌ [VNC] 连接 Proxy 失败: %v", err)
					return
				}

				// 1.发送目标信息头 (User|Shop\n)
				header := fmt.Sprintf("%s|%s\n", targetUser, targetShop)
				if _, err := infoStream.Write([]byte(header)); err != nil {
					log.Printf("❌ [VNC] 发送目标头失败: %v", err)
					infoStream.Close()
					return
				}

				var resp struct {
					PeerID string   `json:"peer_id"`
					Addrs  []string `json:"addrs"`
				}
				if err := json.NewDecoder(infoStream).Decode(&resp); err != nil {
					log.Printf("❌ [VNC] 解析目标信息失败: %v", err)
					infoStream.Close()
					return
				}
				infoStream.Close()

				pid, err := peer.Decode(resp.PeerID)
				if err != nil {
					log.Printf("❌ [VNC] 无效的 PeerID: %v", err)
					return
				}
				targetPeerID = pid

				// 2. 尝试 P2P 直连 (Hole Punching)
				log.Printf("🔍 [VNC] 尝试 P2P 打洞连接目标 <%s> (地址数: %d)...", targetPeerID.ShortString(), len(resp.Addrs))

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
					log.Printf("⚠️ [VNC] P2P 连接尝试失败 (将尝试通过 Relay): %v", err)
					// 不返回，继续尝试 NewStream，Libp2p 会自动寻找路径
				} else {
					log.Printf("🚀 [VNC] P2P 直连成功")
				}
				cancel()

				// 更新缓存
				cachedTargetPeerID = targetPeerID
			}

			// 3. 打开数据流 (带重试和明确的超时)
			var s network.Stream
			// 尝试次数
			const maxRetries = 2
			for i := 0; i < maxRetries; i++ {
				// 给每次尝试 10 秒超时 (总共 20 秒)
				streamCtx, cancelStream := context.WithTimeout(ctx, 10*time.Second)
				s, err = h.NewStream(streamCtx, targetPeerID, protocol.ID(VNCTargetProtocol))
				cancelStream()

				if err == nil {
					break
				}
				log.Printf("⚠️ [VNC] 打开数据流失败 (第 %d/%d 次): %v", i+1, maxRetries, err)

				// 如果是最后一次尝试，不需要 Sleep
				if i < maxRetries-1 {
					// 稍微等待一下 (指数退避 or 固定)
					time.Sleep(1 * time.Second)

					// 如果是连接问题，尝试关闭连接强制重连 (仅当非 cached 时? 或者总是?)
					// 如果连接是 "假死"，关闭它可能有助于下次重试
					if !useCached {
						// h.Network().ClosePeer(targetPeerID) // 慎用，可能会导致正在建立的连接断开
					}
				}
			}

			if err != nil {
				log.Printf("❌ [VNC] 打开数据流最终失败: %v", err)
				// 如果复用失败（例如连接假死），清除缓存，下次强制重连
				cachedTargetPeerID = ""

				// 强制断开连接，以便下次从头开始 (Clean Slate)
				h.Network().ClosePeer(targetPeerID)
				return
			}
			defer s.Close()

			// 2. 发送目标VNC服务器的IP地址和端口
			// 兼容旧版：端口为 8900 时只发送 IP
			vncAddr := formatVncTargetAddr(targetIP, targetPort)
			if _, err := s.Write([]byte(vncAddr)); err != nil {
				log.Printf("❌ [VNC] 发送目标地址失败: %v", err)
				s.Reset()
				return
			}

			log.Printf("✅ [VNC] 通道建立成功，开始转发数据 (Mode: P2P)")

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
			var wg sync.WaitGroup
			wg.Add(2)

			// Viewer -> P2P Agent
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(s, c); err != nil && err != io.EOF {
					log.Printf("⚠️ copy viewer->p2p error: %v", err)
				}
				// 告诉远程 Agent 我们发完了
				if cw, ok := s.(interface{ CloseWrite() error }); ok {
					_ = cw.CloseWrite()
				}
			}()

			// P2P Agent -> Viewer
			go func() {
				defer wg.Done()
				if _, err := copyBuffered(c, s); err != nil && err != io.EOF {
					log.Printf("⚠️ copy p2p->viewer error: %v", err)
				}
				// 尝试关闭本地 TCP 的写端，触发 Viewer 的 EOF
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

// ✅ 新增辅助函数：从 Proxy 获取目标的 P2P 地址信息
func fetchVNCPeerInfo(ctx context.Context, h host.Host, proxyPID peer.ID, tUser, tShop string, tIP string) (*peer.AddrInfo, error) {
	s, err := h.NewStream(ctx, proxyPID, protocol.ID(VNCPeerInfoProtocol))
	if err != nil {
		return nil, err
	}
	defer s.Close()

	// 发送查询请求
	// 1.发送目标信息头 (User|Shop\n)
	header := fmt.Sprintf("%s|%s\n", tUser, tShop)
	if _, err := s.Write([]byte(header)); err != nil {
		log.Printf("❌ [VNC] 发送目标头失败: %v", err)
		return nil, err
	}

	// // 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
	// // 这里可以根据配置或者参数传递实际的IP地址
	// vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
	// if tIP != "" {
	// 	vncIP = tIP
	// }
	// if _, err := s.Write([]byte(vncIP + "\n")); err != nil {
	// 	log.Printf("❌ [VNC] 发送目标IP地址失败: %v", err)
	// 	return nil, err
	// }

	// 读取响应 JSON
	reader := bufio.NewReader(s)
	line, err := reader.ReadBytes('\n')
	if err != nil {
		return nil, err
	}

	// 检查是否是错误消息
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

	info := &peer.AddrInfo{
		ID: targetID,
	}
	for _, addrStr := range resp.Addrs {
		if madder, err := multiaddr.NewMultiaddr(addrStr); err == nil {
			info.Addrs = append(info.Addrs, madder)
		}
	}

	return info, nil
}
