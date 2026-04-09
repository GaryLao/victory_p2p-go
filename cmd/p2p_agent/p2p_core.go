package main

import (
	"bufio"
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"strings"
	"sync/atomic"
	"time"

	"github.com/graphql-go/graphql"
	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/peerstore"
	"github.com/libp2p/go-libp2p/core/protocol"
	"github.com/libp2p/go-libp2p/p2p/host/autorelay"
	rcmgr "github.com/libp2p/go-libp2p/p2p/host/resource-manager"
	v2client "github.com/libp2p/go-libp2p/p2p/protocol/circuitv2/client"
	"github.com/multiformats/go-multiaddr"

	_ "github.com/lib/pq"
)

// lzm modify 2026-01-05 03:47:39
// 启动连接守护 (请在 main 函数中 host 启动后调用此函数)
//
//	func startReconnectionMonitor(ctx context.Context, h host.Host, targetPeerID peer.ID) {
//		// log.Printf("🚀 启动连接守护进程，目标 p2p_proxy: %s", targetPeerID)
//		log.Printf("🚀 [连接守护] 启动，目标 p2p_proxy: %s", targetPeerID)
//
//		// ✅ 1. 定义原子变量 (必须在 Notify 闭包外部定义)
//		// 0: 未注册, 1: 正在注册
//		var isRegistering atomic.Int32
//
//		// // ✅ 初始化状态：启动时先检查一次当前状态
//		// if h.Network().Connectedness(targetPeerID) == network.Connected {
//		// 	isProxyOnline.Store(true)
//		// } else {
//		// 	isProxyOnline.Store(false)
//		// }
//
//		// 1. 注册网络事件监听 (实时响应连接/断开)
//		h.Network().Notify(&network.NotifyBundle{
//			ConnectedF: func(n network.Network, c network.Conn) {
//				// lzm modify 2025-12-21 01:38:01
//				// 重复发送注册请求的问题，增加一个原子锁（CAS）来防止短时间内的重复执行。
//				//
//				// if c.RemotePeer() == targetPeerID {
//				// 	log.Printf("✅ 已连接到 p2p_proxy (%s)，正在发起身份注册...", targetPeerID)
//				// 	// isProxyOnline.Store(true) // ✅ 标记为在线，允许新流量
//				//
//				// 	// 连接建立后，立即发起身份注册
//				// 	go registerToServerB(ctx, h, targetPeerID)
//				// }
//
//				// 过滤非目标节点的连接
//				if c.RemotePeer() != targetPeerID {
//					return
//				}
//
//				// 防抖逻辑 (CAS: Compare And Swap)
//				// 当底层建立多条连接（如 IPv4 + IPv6）时，只允许第一个触发注册
//				// 如果当前值为 0，则设置为 1 并返回 true (执行注册)
//				// 如果当前值为 1，则返回 false (跳过注册)
//				if !isRegistering.CompareAndSwap(0, 1) {
//					// log.Printf("⚠️ [连接守护] 忽略并发连接事件 (正在注册中): %s", c.RemoteMultiaddr())
//					return
//				}
//
//				log.Printf("✅ 已连接到 p2p_proxy (%s)，正在发起身份注册...", targetPeerID)
//
//				// 连接建立后，立即发起身份注册
//				go func() {
//					// 注册结束后重置状态 (defer 确保无论成功失败都会执行)
//					// 增加短暂延迟，防止同一时刻的并发连接抖动
//					defer func() {
//						time.Sleep(2 * time.Second)
//						isRegistering.Store(0)
//					}()
//
//					registerToServerB(ctx, h, targetPeerID)
//				}()
//			},
//			DisconnectedF: func(n network.Network, c network.Conn) {
//				if c.RemotePeer() == targetPeerID {
//					log.Printf("❌ 与 p2p_proxy (%s) 断开连接", targetPeerID)
//					// isProxyOnline.Store(false) // ✅ 标记为离线，拦截新流量
//				}
//			},
//		})
//
//		// 2. 启动定时检查循环 (Watchdog，防止事件漏掉或长期未连接)
//		go func() {
//			ticker := time.NewTicker(5 * time.Second)
//			defer ticker.Stop()
//
//			// 定义 p2p_proxy 的默认回退地址
//			fallbackAddr, _ := multiaddr.NewMultiaddr(ADVERSER)
//
//			// 失败计数器，用于控制日志频率
//			failCount := 0
//
//			// lzm modify 2025-12-21 01:45:54
//			// 重复发送注册请求的问题，增加一个原子锁（CAS）来防止短时间内的重复执行。
//			//
//			// 定义一个可复用的连接函数
//			// tryConnect := func() {
//			// 	if h.Network().Connectedness(targetPeerID) != network.Connected {
//			// 		// 确保状态同步（防止极少数情况下事件漏发）
//			// 		// isProxyOnline.Store(false)
//			//
//			// 		// 1. 检查 Peerstore 中是否有 p2p_proxy 的地址
//			// 		addrs := h.Peerstore().Addrs(targetPeerID)
//			// 		// 2. 如果没有地址（MDNS 还没发现），手动注入回退地址
//			// 		if len(addrs) == 0 {
//			// 			log.Println("⚠️ 暂无 p2p_proxy 地址信息，注入默认回退地址 (" + ADVERSER + ")...")
//			// 			h.Peerstore().AddAddr(targetPeerID, fallbackAddr, peerstore.TempAddrTTL)
//			// 		}
//			//
//			// 		connectCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
//			// 		err := h.Connect(connectCtx, peer.AddrInfo{ID: targetPeerID, Addrs: []ma.Multiaddr{fallbackAddr}})
//			// 		cancel()
//			//
//			// 		if err != nil {
//			// 			failCount++
//			// 			// 静默策略：仅在第1次失败，或每11次(约1分钟)打印一次错误日志
//			// 			if failCount == 1 || failCount%10 == 0 {
//			// 				log.Printf("⚠️ [连接守护] 无法连接 p2p_proxy (已尝试 %d 次): %v", failCount, err)
//			// 			}
//			// 		} else {
//			// 			// 连接成功，重置计数器 (ConnectedF 回调会处理后续逻辑)
//			// 			failCount = 0
//			//
//			// 			// 在上面的 ConnectedF 连接成功时已输出日志和注册身份，这里不重复打印
//			// 			// log.Println("✅ 重连 p2p_proxy 成功！")
//			//
//			// 			// 详细解释
//			// 			// 	1. h.Connect 的工作机制：当你调用 h.Connect 并成功建立连接
//			// 			// 	2. ConnectedF 的工作机制：当一个新的连接被建立时，libp2p 会自动触发 ConnectedF 回调。
//			// 			//	3. 顺序流：
//			// 			//		Watchdog (h.Connect) -> 成功 -> libp2p 内部 -> ConnectedF (发起注册)
//			// 		}
//			// 	} else {
//			// 		// 已连接，重置失败计数
//			// 		failCount = 0
//			// 	}
//			// }
//			//
//			// 循环检查
//			for {
//				select {
//				case <-ctx.Done():
//					return
//				case <-ticker.C:
//					// tryConnect()
//
//					// 如果 "未注册" (即没有活跃的心跳流)，则发起重连
//					// 注意：h.Network().Connectedness 只能反映物理连接，不能反映业务可以通
//					// 我们使用 isRegistered 标记业务是否在线
//					if !isRegistered.Load() {
//						// 如果物理连接也不在，或者物理连接在但业务没通，都尝试重新拨号
//						dialProxy(ctx, h, targetPeerID)
//					}
//				}
//			}
//		}()
//	}
func startReconnectionMonitor(ctx context.Context, h host.Host, targetPeerID peer.ID) {
	// log.Printf("🚀 启动连接守护进程，目标 p2p_proxy: %s", targetPeerID)
	log.Printf("🚀 [连接守护] 启动，目标 p2p_proxy: %s", targetPeerID)

	// ✅ 1. 定义原子变量 (必须在 Notify 闭包外部定义)
	// 0: 未注册, 1: 正在注册
	var isRegistering atomic.Int32

	// // ✅ 初始化状态：启动时先检查一次当前状态
	// if h.Network().Connectedness(targetPeerID) == network.Connected {
	// 	isProxyOnline.Store(true)
	// } else {
	// 	isProxyOnline.Store(false)
	// }

	// 1. 注册网络事件监听 (实时响应连接/断开)
	h.Network().Notify(&network.NotifyBundle{
		ConnectedF: func(n network.Network, c network.Conn) {
			// lzm modify 2025-12-21 01:38:01
			// 重复发送注册请求的问题，增加一个原子锁（CAS）来防止短时间内的重复执行。
			//
			// if c.RemotePeer() == targetPeerID {
			// 	log.Printf("✅ 已连接到 p2p_proxy (%s)，正在发起身份注册...", targetPeerID)
			// 	// isProxyOnline.Store(true) // ✅ 标记为在线，允许新流量
			//
			// 	// 连接建立后，立即发起身份注册
			// 	go registerToServerB(ctx, h, targetPeerID)
			// }

			// 过滤非目标节点的连接
			if c.RemotePeer() != targetPeerID {
				return
			}

			// 防抖逻辑 (CAS: Compare And Swap)
			// 当底层建立多条连接（如 IPv4 + IPv6）时，只允许第一个触发注册
			// 如果当前值为 0，则设置为 1 并返回 true (执行注册)
			// 如果当前值为 1，则返回 false (跳过注册)
			if !isRegistering.CompareAndSwap(0, 1) {
				// log.Printf("⚠️ [连接守护] 忽略并发连接事件 (正在注册中): %s", c.RemoteMultiaddr())
				return
			}

			// log.Printf("✅ 已连接到 p2p_proxy (%s)，正在发起身份注册...", targetPeerID)

			// 连接建立后，立即发起身份注册
			go func() {
				// 注册结束后重置状态 (defer 确保无论成功失败都会执行)
				// 增加短暂延迟，防止同一时刻的并发连接抖动
				defer func() {
					time.Sleep(2 * time.Second)
					isRegistering.Store(0)
				}()

				// 这里的 ConnectedF 仅用于被动连接（例如 Proxy 主动连我，或者其他地方 Connect 了）
				// 但我们的架构通常是 Active DialMode
				// 为了避免冲突，这里可以保留，也可以禁用。
				// 为稳妥起见，如果这里触发了，还是去注册一下。
				// 但由于 dialProxy 里已经做了注册，且是阻塞的。
				// 如果已经在 dialProxy 里阻塞了，这里再注册会多余吗？
				// dialProxy 是 Loop 调用。ConnectedF 是事件回调。
				// 如果 dialProxy 正在 Connect，Connect 成功后会触发 ConnectedF。
				// 所以 dialProxy 里不要重复 Register，或者 unify 逻辑。

				// 修正设计：
				// dialProxy 负责：Ensure Connection -> Block Read (Keepalive)
				// NotifyBundle 负责：Logging / Cleanup
				// 让我们把 ConnectedF 里的业务逻辑去掉，只留日志。
				// 真正的注册逻辑完全交给 dialProxy (Loop)。

				// log.Printf("🔗 [Event] 底层连接建立: %s", c.RemoteMultiaddr())
			}()
		},
		DisconnectedF: func(n network.Network, c network.Conn) {
			if c.RemotePeer() == targetPeerID {
				log.Printf("❌ 与 p2p_proxy (%s) 断开连接", targetPeerID)
				// isProxyOnline.Store(false) // ✅ 标记为离线，拦截新流量
			}
		},
	})

	// 2. 启动定时检查循环 (Watchdog，防止事件漏掉或长期未连接)
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		// 定义 p2p_proxy 的默认回退地址
		// fallbackAddr, _ := multiaddr.NewMultiaddr(ADVERSER)

		// 失败计数器，用于控制日志频率
		// failCount := 0

		// lzm modify 2025-12-21 01:45:54
		// 重复发送注册请求的问题，增加一个原子锁（CAS）来防止短时间内的重复执行。
		//
		// 定义一个可复用的连接函数
		// tryConnect := func() {
		// 	if h.Network().Connectedness(targetPeerID) != network.Connected {
		// 		// 确保状态同步（防止极少数情况下事件漏发）
		// 		// isProxyOnline.Store(false)
		//
		// 		// 1. 检查 Peerstore 中是否有 p2p_proxy 的地址
		// 		addrs := h.Peerstore().Addrs(targetPeerID)
		// 		// 2. 如果没有地址（MDNS 还没发现），手动注入回退地址
		// 		if len(addrs) == 0 {
		// 			log.Println("⚠️ 暂无 p2p_proxy 地址信息，注入默认回退地址 (" + ADVERSER + ")...")
		// 			h.Peerstore().AddAddr(targetPeerID, fallbackAddr, peerstore.TempAddrTTL)
		// 		}
		//
		// 		connectCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		// 		err := h.Connect(connectCtx, peer.AddrInfo{ID: targetPeerID, Addrs: []ma.Multiaddr{fallbackAddr}})
		// 		cancel()
		//
		// 		if err != nil {
		// 			failCount++
		// 			// 静默策略：仅在第1次失败，或每11次(约1分钟)打印一次错误日志
		// 			if failCount == 1 || failCount%10 == 0 {
		// 				log.Printf("⚠️ [连接守护] 无法连接 p2p_proxy (已尝试 %d 次): %v", failCount, err)
		// 			}
		// 		} else {
		// 			// 连接成功，重置计数器 (ConnectedF 回调会处理后续逻辑)
		// 			failCount = 0
		//
		// 			// 在上面的 ConnectedF 连接成功时已输出日志和注册身份，这里不重复打印
		// 			// log.Println("✅ 重连 p2p_proxy 成功！")
		//
		// 			// 详细解释
		// 			// 	1. h.Connect 的工作机制：当你调用 h.Connect 并成功建立连接
		// 			// 	2. ConnectedF 的工作机制：当一个新的连接被建立时，libp2p 会自动触发 ConnectedF 回调。
		// 			//	3. 顺序流：
		// 			//		Watchdog (h.Connect) -> 成功 -> libp2p 内部 -> ConnectedF (发起注册)
		// 		}
		// 	} else {
		// 		// 已连接，重置失败计数
		// 		failCount = 0
		// 	}
		// }
		//
		// 循环检查
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				// tryConnect()

				// 如果 "未注册" (即没有活跃的心跳流)，则发起重连
				// 注意：h.Network().Connectedness 只能反映物理连接，不能反映业务可以通
				// 我们使用 isRegistered 标记业务是否在线
				if !isRegistered.Load() {
					// 如果物理连接也不在，或者物理连接在但业务没通，都尝试重新拨号
					dialProxy(ctx, h, targetPeerID)
				}
			}
		}
	}()
}

// dialProxy (替代原有的 tryConnect)
// 负责：建立连接 -> 身份注册 -> 保持心跳 (阻塞) (替代了 registerToServerB)
func dialProxy(ctx context.Context, h host.Host, pid peer.ID) {
	// 1. 确保 Peerstore 中有地址 (注入回退地址，防止 DHT 没找到时无法连接)
	if fallbackAddr, err := multiaddr.NewMultiaddr(ADVERSER); err == nil {
		h.Peerstore().AddAddr(pid, fallbackAddr, peerstore.TempAddrTTL)
	}

	log.Printf("🔄 [连接p2p_proxy] 正在尝试建立物理连接 (包含 TCP/UDP)...")

	// 2. 构造 Proxy 多协议地址信息
	// 从 ADVERSER (TCP) 推导出 UDP 地址作为备选
	var proxyAddrs []multiaddr.Multiaddr
	if tcpAddr, err := multiaddr.NewMultiaddr(ADVERSER); err == nil {
		proxyAddrs = append(proxyAddrs, tcpAddr)
		// 简单的推导逻辑
		tcpVal, _ := tcpAddr.ValueForProtocol(multiaddr.P_TCP)
		ipVal, _ := tcpAddr.ValueForProtocol(multiaddr.P_IP4)
		if ipVal != "" && tcpVal != "" {
			if udpAddr, err := multiaddr.NewMultiaddr(fmt.Sprintf("/ip4/%s/udp/%s/quic-v1", ipVal, tcpVal)); err == nil {
				proxyAddrs = append(proxyAddrs, udpAddr)
			}
		}
	}

	// 3. 发起物理探测
	// 我们希望至少建立一个连接，最好是 UDP。LibP2P 默认会尝试所有地址。
	dialCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	if err := h.Connect(dialCtx, peer.AddrInfo{ID: pid, Addrs: proxyAddrs}); err != nil {
		log.Printf("❌ [连接p2p_proxy] 物理连接失败: %v", err)
		return
	}

	// 检查当前连接协议，如果是纯 TCP，尝试后台静默升级到 UDP/QUIC
	go func() {
		// lzm modify 2026-01-20 18:18:06
		// time.Sleep(2 * time.Second)
		//
		// 使用 select 替代 time.Sleep，支持 context 取消
		select {
		case <-ctx.Done():
			return
		case <-time.After(2 * time.Second):
		}

		hasUDP := false
		for _, c := range h.Network().ConnsToPeer(pid) {
			if strings.Contains(c.RemoteMultiaddr().String(), "/udp/") {
				hasUDP = true
				break
			}
		}
		if !hasUDP {
			log.Printf("📡 [连接p2p_proxy] 检测到仅有 TCP 通道，尝试强制激活 UDP/QUIC 打洞路径...")
			for _, addr := range proxyAddrs {
				if strings.Contains(addr.String(), "/udp/") {
					// lzm modify 2026-01-20 18:18:06
					// // 异步非阻塞尝试，不影响现有注册流
					// go h.Connect(context.Background(), peer.AddrInfo{ID: pid, Addrs: []multiaddr.Multiaddr{addr}})
					//
					// 为什么这样修改更好？
					// 原始代码使用 context.Background() 的问题是：如果主连接已经断开需要重连，这个后台 goroutine 仍然在尝试连接，并且可能无限阻塞。
					// 修改后使用带超时的 context，确保：
					//
					// 	1. 最多阻塞 10 秒
					// 	2. 当父 ctx 取消（如程序退出）时，也会取消这个连接尝试
					// 	3. defer cf() 确保 cancel 函数被调用，避免 context 泄漏
					//
					// 使用带超时的 context，避免长期阻塞
					upgradeCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
					go func(c context.Context, cf context.CancelFunc) {
						defer cf()
						h.Connect(c, peer.AddrInfo{ID: pid, Addrs: []multiaddr.Multiaddr{addr}})
					}(upgradeCtx, cancel)
				}
			}
		}
	}()

	// // 打开业务流 (原 registerToServerB 的逻辑移到这里)(对应 Proxy 的 handleRegistration)
	// s, err := h.NewStream(ctx, pid, P2PProtocol)
	// if err != nil {
	// 	log.Printf("❌ [注册p2p_proxy] 打开业务流失败: %v", err)
	// 	return
	// }
	// defer s.Close()
	//
	// // 发送身份注册信息 (原 registerToServerB 的逻辑移到这里)
	// regInfo := map[string]string{
	// 	"user_id":  getUserIDFromRegistry(),
	// 	"shopid":   getShopIDFromIni(),
	// 	"shopname": getShopNameFromIni(),
	// }
	// bytes, _ := json.Marshal(regInfo)
	// // 发送 JSON + 换行符
	// if _, err := s.Write(append(bytes, '\n')); err != nil {
	// 	log.Printf("❌ [注册p2p_proxy] 发送注册信息失败: %v", err)
	// 	return
	// }
	//
	// // === 注册成功，标记全局状态 ===
	// isRegistered.Store(true)
	// log.Printf("✅ [注册p2p_proxy] 注册成功，通道已建立 (保持在线中...)")
	//
	// // 4. 阻塞读取 (心跳保活)
	// // 只要这个循环不退，就代表连接正常。一旦退出，外层就会重连。
	// buf := make([]byte, 1024)
	// for {
	// 	// 设置读取超时 (例如 15 秒)，p2p_proxy 每 5 秒发一次心跳
	// 	// 如果 15 秒没收到数据，说明网络断了
	// 	s.SetReadDeadline(time.Now().Add(15 * time.Second))
	//
	// 	_, err := s.Read(buf)
	// 	if err != nil {
	// 		log.Printf("❌ [连接p2p_proxy] 与服务器断开 (读取超时或错误): %v", err)
	// 		return // 退出函数 -> 触发外层 startReconnectionMonitor 重连
	// 	}
	// 	// 收到心跳数据，循环继续，保持连接
	// }
	//
	// 3. 连接成功，发起注册并阻塞等待 (直到断开)
	// 注意：这里是同步调用，会一直阻塞在这里，直到 registerToServerB 返回
	registerToServerB(ctx, h, pid)
}

// registerToServerB 发送身份信息并保持阻塞读取，直到流断开
func registerToServerB(ctx context.Context, h host.Host, targetPID peer.ID) {
	// 打开流 (对应 Proxy 的 handleRegistration)
	s, err := h.NewStream(ctx, targetPID, protocol.ID(P2PProtocol))
	if err != nil {
		log.Printf("❌ [注册] 打开流失败: %v", err)
		return
	}
	defer s.Close()

	// 构造认证信息 (V8: 增加详细地址上报)
	var addrStrings []string
	for _, a := range h.Addrs() {
		addrStrings = append(addrStrings, a.String())
	}

	authData := map[string]interface{}{
		"user_id":   getUserIDFromRegistry(),
		"shopid":    getShopIDFromIni(),
		"shopname":  getShopNameFromIni(),
		"addresses": addrStrings, // ✅ 新增：把自感知的地址全发给 Proxy
	}
	jsonData, err := json.Marshal(authData)
	if err != nil {
		log.Printf("❌ [注册] 序列化认证信息失败: %v", err)
		return
	}

	// 发送认证信息 (带超时防止卡死)
	s.SetWriteDeadline(time.Now().Add(5 * time.Second))
	_, err = s.Write(append(jsonData, '\n'))
	s.SetWriteDeadline(time.Time{}) // 清除超时

	if err != nil {
		log.Printf("❌ [注册] 发送认证信息失败: %v", err)
		return
	}

	log.Printf("✅ [注册] 注册成功，通道已建立 (保持在线中...)")

	// ✅ V15 增强：读写分离并发模型 (彻底消除 I/O 阻塞导致的状态同步延迟)
	forceReserveChan := make(chan bool, 1)
	forceReportChan := make(chan bool, 1)

	// --- 协程 1: 中继预约监控协程 ---
	go func() {
		isFirstReserve := true // 首次执行标记
		lastReserveOK := false // 上次预约是否成功

		for {
			// 静默日志策略：仅在首次执行时输出 "正在申请" 日志
			if isFirstReserve {
				log.Printf("📡 [Relay] 正在向 Proxy 申请中心继续期 (保活)...")
			}

			res, err := v2client.Reserve(ctx, h, peer.AddrInfo{ID: targetPID})

			interval := 10 * time.Minute
			if err != nil {
				// 失败时始终输出日志
				log.Printf("⚠️ [Relay] 申请预留失败: %v，将在 1 分钟后重试", err)
				interval = 1 * time.Minute
				lastReserveOK = false
			} else {
				// 静默日志策略：仅在首次成功或从失败恢复成功时输出日志
				if isFirstReserve || !lastReserveOK {
					log.Printf("✅ [Relay] 申请预留成功！到期时间: %s", res.Expiration)
				}
				lastReserveOK = true

				// 预约成功后，立即触发状态上报
				select {
				case forceReportChan <- true:
				default:
				}
			}

			isFirstReserve = false // 首次执行完成

			select {
			case <-ctx.Done():
				return
			case <-forceReserveChan:
				log.Printf("🔔 [Relay] 收到强制预留指令，立即执行预约...")
			case <-time.After(interval):
			}
		}
	}()

	// --- 协程 2: 指令接收协程 (只读) ---
	go func() {
		bufReader := bufio.NewReader(s)
		for {
			// 设置较长的读取超时，Proxy 会发心跳
			s.SetReadDeadline(time.Now().Add(60 * time.Second))
			line, err := bufReader.ReadBytes('\n')
			if err != nil {
				// 读取失败说明流断开，触发主循环退出
				isRegistered.Store(false)
				return
			}

			var msg map[string]string
			if err := json.Unmarshal(line, &msg); err == nil {
				if msg["cmd"] == "reserve" {
					select {
					case forceReserveChan <- true:
					default:
					}
				}
			}
		}
	}()

	// --- 协程 3 (主循环): 状态同步协程 (只写) ---
	isRegistered.Store(true)
	defer isRegistered.Store(false)

	lastAddrCount := 0
	isFirstReport := true                     // 首次上报标记
	ticker := time.NewTicker(5 * time.Second) // 兼顾地址变化检测频率
	defer ticker.Stop()

	for {
		doReport := false
		currentAddrs := h.Addrs()

		select {
		case <-ctx.Done():
			return
		case <-forceReportChan:
			doReport = true
		case <-ticker.C:
			// 定时检测地址变化
			if len(currentAddrs) != lastAddrCount {
				doReport = true
			}
			// 检查业务连通性 (若读协程标记断开则退出)
			if !isRegistered.Load() {
				return
			}
		}

		if doReport {
			// 静默日志策略：仅在首次上报或地址数量变化时输出日志
			addrChanged := len(currentAddrs) != lastAddrCount
			if isFirstReport || addrChanged {
				log.Printf("📡 [注册] 正在同步自身状态 (包含中继路径, 地址数: %d)...", len(currentAddrs))
				isFirstReport = false
			}
			lastAddrCount = len(currentAddrs)

			var addrStrings []string
			for _, a := range currentAddrs {
				addrStrings = append(addrStrings, a.String())
			}
			// 显式公示中继地址，加速 Proxy 验证
			relayAddr := fmt.Sprintf("/p2p/%s/p2p-circuit/p2p/%s", targetPID.String(), h.ID().String())
			addrStrings = append(addrStrings, relayAddr)

			authData := map[string]interface{}{
				"user_id":   getUserIDFromRegistry(),
				"shopid":    getShopIDFromIni(),
				"shopname":  getShopNameFromIni(),
				"addresses": addrStrings,
			}
			jsonData, err := json.Marshal(authData)
			if err != nil {
				log.Printf("⚠️ [注册] 序列化状态信息失败: %v", err)
				continue
			}
			s.SetWriteDeadline(time.Now().Add(5 * time.Second))
			s.Write(append(jsonData, '\n'))
			s.SetWriteDeadline(time.Time{})
		}
	}
}

func isOutboundConnection(s network.Stream) bool {
	return s.Stat().Direction == network.DirOutbound
}

func logConnectionInfo(s network.Stream) {
	direction := "inbound"
	if isOutboundConnection(s) {
		direction = "outbound"
	}
	log.Printf("连接方向: %s", direction)
}

func sendVersionNegotiation(s network.Stream) {
}

// 处理入站流
func handleStream(s network.Stream) {
	// 1. 基础设置
	// remotePeer := s.Conn().RemotePeer()
	// log.Printf("协议已协商成功，开始处理入站流（来自 %s）", remotePeer)

	// 确保函数结束时关闭流资源
	defer s.Close()

	// 设置读写超时 (防止死锁，例如 30秒)
	s.SetReadDeadline(time.Now().Add(ReadTimeout))
	s.SetWriteDeadline(time.Now().Add(WriteTimeout))

	// 2. 读取请求 (注意：不要使用 for 循环，因为 p2p_proxy 是一次请求一个流)
	reader := bufio.NewReader(s)

	// 读取直到换行符
	line, err := reader.ReadBytes('\n')
	if err != nil {
		if err != io.EOF {
			log.Printf("读取协议头失败: %v", err)
		}
		return
	}

	// 3. 解析协议头
	line = bytes.TrimSpace(line)
	if len(line) == 0 {
		return
	}

	var meta map[string]interface{}
	if err := json.Unmarshal(line, &meta); err != nil {
		log.Printf("协议头解析失败: %v | 内容: %s", err, string(line))
		return
	}

	// 4. 业务处理
	action, ok := meta["action"].(string)
	if !ok || action == "" {
		log.Printf("⚠️ 无效的协议格式: action 字段缺失或类型错误")
		return
	}
	// uid, _ := meta["user_id"].(string)
	// shopid, _ := meta["shopid"].(string)
	// log.Printf("收到请求: action=%s user_id=%s shopid=%s", action, uid, shopid)

	// 根据 action 执行不同逻辑
	if action == "querysql" {
		//antigravity modify 2026-01-23 18:27:04
		// handleQuerySql(s, meta["sql"].(string))
		// 安全地获取 sql 字段 (防止 nil 值导致 panic)
		sqlQuery, ok := meta["sql"].(string)
		if !ok || sqlQuery == "" {
			log.Printf("⚠️ querysql 请求缺少有效的 sql 字段")
			s.Write([]byte(`{"error": "missing or invalid sql field"}`))
			return
		}
		handleQuerySql(s, sqlQuery)
	} else if action == "graphql" {
		// === 新增 GraphQL 支持 ===
		//antigravity modify 2026-01-23 19:05:34
		// query, _ := meta["query"].(string)
		// 安全地获取 query 字段 (防止 nil 值或空字符串)
		query, ok := meta["query"].(string)
		if !ok || query == "" {
			log.Printf("⚠️ graphql 请求缺少有效的 query 字段")
			s.Write([]byte(`{"errors": [{"message": "missing or invalid query field"}]}`))
			return
		}

		// 安全地获取 variables (JSON Unmarshal 默认为 map[string]interface{})
		var variables map[string]interface{}
		if v, ok := meta["variables"].(map[string]interface{}); ok {
			variables = v
		}

		handleGraphQL(s, query, variables)
	} else {
		// 默认处理
		s.Write([]byte("Unknown action\n"))
	}

	// 5. 关键：关闭写入端
	s.CloseWrite()
}

// --- 新增：GraphQL 处理函数 ---
func handleGraphQL(w io.Writer, query string, variables map[string]interface{}) {
	// 执行查询
	params := graphql.Params{
		Schema:         p2pSchema,
		RequestString:  query,
		VariableValues: variables,
	}
	result := graphql.Do(params)

	// 将结果编码为 JSON 并写入流
	// PHP 端收到后可以直接 json_decode
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Printf("GraphQL 响应写入失败: %v", err)
	}
}

func handleQuerySql(w io.Writer, querySQL string) {
	connStr := "postgres://sysdba:masterkey@localhost/victorysvr?sslmode=disable"
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		fmt.Fprintf(w, "DB连接错误: %v", err)
		return
	}
	defer db.Close()

	query := querySQL // 使用传入的 SQL 查询
	// log.Printf("执行 SQL 查询: %s", query)
	rows, err := db.Query(query)
	if err != nil {
		fmt.Fprintf(w, "查询失败: %v", err)
		return
	}
	defer rows.Close()

	jsonData, err := rowsToJSON(rows)
	if err != nil {
		fmt.Fprintf(w, "转换JSON失败: %v", err)
		return
	}
	w.Write(jsonData)
}

func rowsToJSON(rows *sql.Rows) ([]byte, error) {
	columns, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	var results []map[string]interface{}

	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))

		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, err
		}

		rowMap := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			if b, ok := val.([]byte); ok {
				rowMap[col] = string(b)
			} else {
				rowMap[col] = val
			}
		}

		results = append(results, rowMap)
	}

	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)

	if err := encoder.Encode(results); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

// 主动发起流（心跳 + 请求处理）
func startActiveStream(ctx context.Context, h host.Host, serverBID peer.ID) {
	// addr, _ := ma.NewMultiaddr("/ip4/123.57.163.15/tcp/8590") // p2p_proxy 地址
	addr, _ := multiaddr.NewMultiaddr(ADVERSER) // p2p_proxy 地址

	// lzm modify 2025-12-17 16:49:55
	// retryDelay := ReadTimeout
	// for {
	// 	// 连接 p2p_proxy
	// 	if err := h.Connect(ctx, peer.AddrInfo{
	// 		ID:    serverBID,
	// 		Addrs: []ma.Multiaddr{addr},
	// 	}); err != nil {
	// 		// 关闭旧连接（如有）
	// 		h.Network().ClosePeer(serverBID)
	//
	// 		log.Printf("连接 p2p_proxy 失败: %v，%v 后重试...", err, retryDelay)
	// 		time.Sleep(retryDelay)
	// 		retryDelay = min(retryDelay*2, 60*time.Second) // 指数退避
	// 		continue
	// 	}
	// 	retryDelay = ReadTimeout // 成功后重置
	//
	// 	// 连接成功！
	// 	// 身份认证和流保持现在由 startReconnectionMonitor 中的 ConnectedF 回调统一处理 (调用 registerToServerB)
	// 	// 这里不再重复创建流，避免产生多余的连接和 "Client Offline" 问题 (由于错误的 handleStream 调用)
	// 	// log.Println("✅ 成功建立到底层 p2p_proxy 的连接")
	//
	// 	break
	// }
	//
	retryDelay := 5 * time.Second // 初始重试间隔
	failCount := 0
	for {
		// 连接 p2p_proxy
		// 建议加上 Context 超时，防止 Connect 长期阻塞
		connectCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		err := h.Connect(connectCtx, peer.AddrInfo{
			ID:    serverBID,
			Addrs: []multiaddr.Multiaddr{addr},
		})
		cancel()

		if err != nil {
			// 关闭旧连接（如有）
			h.Network().ClosePeer(serverBID)
			failCount++

			// === 静默日志策略 ===
			// 1. 前 3 次失败：打印日志 (快速反馈启动时的错误)
			// 2. 之后每 10 次失败：打印一次 (避免断网期间刷屏，假设 delay=60s，则约 10 分钟一次)
			if failCount <= 3 || failCount%10 == 0 {
				log.Printf("⚠️ [主动连接] 连接 p2p_proxy 失败 (第 %d 次): %v，%v 后重试...", failCount, err, retryDelay)
			}

			time.Sleep(retryDelay)

			// 指数退避：最大等待 60 秒
			retryDelay *= 2
			if retryDelay > 60*time.Second {
				retryDelay = 60 * time.Second
			}
			continue
		}

		// 连接成功！
		// 身份认证和流保持现在由 startReconnectionMonitor 中的 ConnectedF 回调统一处理
		log.Println("✅ 成功建立到底层 p2p_proxy 的连接")
		break
	}

}

func startAgentHostServices() (host.Host, peer.ID) {
	// 这里放置本机作为“服务器”时的逻辑
	ctx := context.Background()

	// === 新增：启动本地 HTTP 代理 ===
	// 这将允许局域网内的其他电脑通过访问 http://192.168.0.101:AgentProxyHttpPort 来获取服务器的内容
	// go startLocalHttpProxy()

	// -------------------------------------------------------------------------
	// 1. 提前准备 Proxy 信息 (为了配置 AutoRelay)
	// -------------------------------------------------------------------------

	// 加载 p2p_proxy 的密钥并生成 Peer ID
	// (注意：这段代码从 libp2p.New 之后移到了这里)
	privKey := loadServerBKey()
	pubKey := privKey.GetPublic()
	serverBID, err := peer.IDFromPublicKey(pubKey)
	if err != nil {
		log.Fatalf("致命错误：无法生成 Peer ID: %v", err)
	}
	log.Printf("p2p_proxy Peer ID: %s", serverBID)

	// 解析 Proxy 的 Multiaddr (ADVERSER 常量需在文件中定义)
	proxyMultiAddr, err := multiaddr.NewMultiaddr(ADVERSER)
	if err != nil {
		log.Fatalf("致命错误：无效的 Proxy 地址 (%s): %v", ADVERSER, err)
	}

	// 构造静态中继节点信息 (与旧版一致，只使用 TCP 地址)
	proxyAddrInfo := peer.AddrInfo{
		ID:    serverBID,
		Addrs: []multiaddr.Multiaddr{proxyMultiAddr},
	}

	// 资源管理器 (恢复为 InfiniteLimits，避免资源限制干扰打洞)
	limiter := rcmgr.NewFixedLimiter(rcmgr.InfiniteLimits)
	rm, err := rcmgr.NewResourceManager(limiter)
	if err != nil {
		log.Fatalf("致命错误：创建资源管理器失败: %v", err)
	}

	h, err := libp2p.New(
		libp2p.Identity(loadServerAKey()), // 使用 p2p_agent 自己的密钥

		// ✅ 恢复旧版配置：只监听 TCP（打洞必须）
		libp2p.ListenAddrStrings("/ip4/0.0.0.0/tcp/0"),

		libp2p.Ping(true), // 启用内置心跳机制
		// libp2p.NATPortMap(), // 暂时关闭 UPnP，避免干扰 NAT 穿透

		libp2p.ResourceManager(rm), // 应用资源管理器

		// =================================================================
		// ✅ 核心修复：配置静态 AutoRelay 以解决 NO_RESERVATION (204)
		// =================================================================

		// AutoNAT (在 v0.25.1 中默认开启，无需显式配置，旧版 API 已移除)
		// libp2p.EnableAutoNAT(),

		// 1. 启用 Relay 客户端
		// 允许本节点通过中继与其他节点通信，并支持发起 Reservation 请求
		// 当使用 libp2p.EnableAutoRelay() 时，中继客户端功能会自动启用
		libp2p.EnableRelay(), // 确保开启中继客户端 (通常默认开启，显式写出更好)
		// libp2p.EnableRelayService(), // ✅ 开启中继服务 (Circuit Relay v2)  //这个只能在服务端开启

		// 2. 启用自动中继 (AutoRelay)
		// 自动检测网络环境，如果发现自己无法被公网直连，
		// 会自动向已连接的 Proxy 申请 Reservation (预留槽位)。
		// 启用自动中继，并指定 Proxy 为静态中继节点
		// 这样 Agent B 启动后会自动向 Proxy 发送 Reserve 请求
		libp2p.EnableAutoRelay(autorelay.WithStaticRelays([]peer.AddrInfo{proxyAddrInfo})),

		// ✅ 恢复旧版配置：强制声明为私有网络，立即触发中继预约和打洞流程
		libp2p.ForceReachabilityPrivate(),

		// 3. 启用打洞 (Hole Punching)
		// 配合 Relay 使用，尝试建立直连，提升传输速度
		libp2p.EnableHolePunching(), // 开启 NAT 打洞 (关键)

		// =================================================================

	)
	if err != nil {
		log.Fatal(err)
	}

	// 因为 defer 会在所在函数返回时执行
	// 不在这里关闭 h
	// defer h.Close()

	// /////////////////////////////////////////////////////
	log.Printf("p2p_agent 启动完成，正在运行中...")
	log.Printf("Peer ID: %s", h.ID())

	// -------------------------------------------------------------------------
	// 3. 连接守护与业务逻辑
	// -------------------------------------------------------------------------

	// 主动连接 Proxy (虽然 AutoRelay 也会连，但显式连接更稳妥)
	// if err := h.Connect(ctx, proxyAddrInfo); err != nil {
	// 	log.Printf("⚠️ 连接 Proxy 失败: %v", err)
	// }
	// /////////////////////////////////////////////////////
	log.Printf(""+AppName+" 监听地址: %s Peer ID: %s", h.Addrs(), h.ID())

	// ✅ 新增：详细打印所有观测到的地址 (包含公网地址)
	go func() {
		time.Sleep(5 * time.Second) // 等待 AutoNAT 发现公网地址
		log.Printf("🔍 [SelfCheck] Agent 自身完整 Multiaddrs: %v", h.Addrs())
	}()

	// 移到上面
	// // 加载 p2p_proxy 的密钥并生成 Peer ID
	// // ...

	// 注册流处理器（处理 p2p_proxy 主动发起的流）
	h.SetStreamHandler(P2PProtocol, func(s network.Stream) {
		go handleStream(s)
	})

	// === 1. 被控端逻辑 (电脑 B/C/D) ===
	// 当 Proxy 转发流量过来时，连接本地 VNC Server (8900)
	h.SetStreamHandler(VNCTargetProtocol, func(s network.Stream) {
		handleVNCConnection(s)
	})

	// 新增：处理 PostgreSQL 请求 -> 转发给本地 5432
	h.SetStreamHandler(PostgresTargetProtocol, func(s network.Stream) {
		handlePostgresConnection(s)
	})

	// === 2. 控制端逻辑 (电脑 A) ===
	// 修改：从 vnc_targets.json 配置文件加载目标列表
	// 加载 VNC 目标配置
	if vncTargets, err := loadVNCTargets(); err == nil {
		log.Printf("📂 已加载 %d 个 VNC 目标配置", len(vncTargets))
		for _, t := range vncTargets {
			// 默认端口 8900
			targetPort := t.TargetPort
			if targetPort == 0 {
				targetPort = 8900
			}
			if ("" == t.ConnectType) || ("proxy" == t.ConnectType) {
				go startVNCClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			} else if "direct" == t.ConnectType {
				go startVNCP2PClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			} else if "direct_proxy" == t.ConnectType {
				go startVNCP2PRelayClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			}
		}
	} else {
		log.Printf("ℹ️ 未检测到 VNC 配置文件或解析失败: %v", err)
	}

	// 新增：加载 PostgreSQL 目标配置并启动监听
	if pgTargets, err := loadPostgresTargets(); err == nil {
		log.Printf("📂 已加载 %d 个 PostgreSQL 目标配置", len(pgTargets))
		for _, t := range pgTargets {
			// 默认端口 5432
			targetPort := t.TargetPort
			if targetPort == 0 {
				targetPort = 5432
			}
			if ("" == t.ConnectType) || ("proxy" == t.ConnectType) {
				go startPostgresClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			} else if "direct" == t.ConnectType {
				go startPostgresP2PClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			} else if "direct_proxy" == t.ConnectType {
				go startPostgresP2PRelayClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP, targetPort)
			}
		}
	} else {
		log.Printf("ℹ️ 未检测到 PG 配置文件 (pg_targets.json) 或解析失败，跳过 PG 客户端启动: %v", err)
	}
	// ================================================

	// === 在获取到 host 和 serverBID 后启动代理 ===
	// 启动本地 HTTP 代理
	go startLocalHttpProxy(h, serverBID)
	// ================================================

	// 调整启动顺序：先启动连接监控，确保能捕获到 startActiveStream 建立的连接事件
	// 这样一旦连接建立，ConnectedF 回调就会触发 registerToServerB 进行注册
	go startReconnectionMonitor(ctx, h, serverBID)

	// lzm comm 2025-12-17 17:14:13
	// 统一连接逻辑，让一个函数专门负责连接和重连，另一个只做辅助。
	// 推荐的方案是：移除 startActiveStream 函数，将它的逻辑合并到 startReconnectionMonitor 中。
	// // 启动主动连接尝试（仅负责建立底层连接）
	// // go startActiveStream(ctx, h, serverBID)

	// ✅ 新增：启动 PostgreSQL 代理服务
	go startPgProxyServices(ctx, h, serverBID)

	return h, serverBID
}
