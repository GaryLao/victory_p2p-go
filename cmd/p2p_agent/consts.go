package main

import "time"

const (
	AppTitle = "P2P_Agent_Client"
	AppName  = "p2p_agent"

	ProtocolPrefix  = "p2p_proxy"
	ProtocolVersion = "1.0.0"
	P2PProtocol     = "/" + ProtocolPrefix + "/" + ProtocolVersion
	// PingProtocol    = "/ping/" + ProtocolVersion

	// TunnelProtocol 新增：定义隧道协议 ID (必须与服务端一致)
	TunnelProtocol = "/" + ProtocolPrefix + "/tunnel/1.0.0"

	PostgresTunnelProtocol = "/" + ProtocolPrefix + "/pgtunnel/1.0.0" // ✅ 新增：用于 PostgreSQL 隧道

	// VNCRelayProtocol 新增：VNC 中继协议 (Agent A -> Proxy)
	VNCRelayProtocol = "/" + ProtocolPrefix + "/vnc_relay/1.0.0"
	// VNCTargetProtocol 新增：VNC 目标协议 (Proxy -> Agent B)
	VNCTargetProtocol = "/" + ProtocolPrefix + "/vnc_target/1.0.0"

	// VNCPeerInfoProtocol
	// 说明: 增加一个“信令”协议，返回目标 B 的 peer.ID 和 multiaddr。
	// 		A 通过该信息直接连接 B，VNC 数据不再走 Proxy 中继。
	VNCPeerInfoProtocol = "/" + ProtocolPrefix + "/vnc_peerinfo/1.0.0"

	// PostgresRelayProtocol 新增：PostgreSQL 协议定义 (必须与 Proxy 一致)
	PostgresRelayProtocol    = "/" + ProtocolPrefix + "/pg_relay/1.0.0"
	PostgresTargetProtocol   = "/" + ProtocolPrefix + "/pg_target/1.0.0"
	PostgresPeerInfoProtocol = "/" + ProtocolPrefix + "/pg_peerinfo/1.0.0"

	ReadTimeout          = 30 * time.Second
	WriteTimeout         = 30 * time.Second
	CurrentFormatVersion = 1

	clientOnlineTimeout    = 1 * time.Minute // 副机在线状态判断阈值
	cleanupInactiveTimeout = 12 * time.Hour  // 清理超时副机连接阈值

	AgentClientsidePort = "8386" // p2p_agent 用于监听局域网副机的长连接和心跳
	AgentClientHttpPort = "9301" // p2p_agent 用于管理主机和副机的 http 接口和 debug.pprof 端口（比如：查看在线副机和推送更新信息到副机）
	AgentProxyHttpPort  = "9300" // p2p_agent 接收局域网代理 HTTP 请求并转发到云端服务器

	ProxyListenPort = "8590" // p2p_proxy 监听端口

	BkeyFileName = "p2p_proxy.key"
	// AkeyFileName = "p2p_agent.key" // p2p_agent 私钥文件名
)
