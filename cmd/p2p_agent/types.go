package main

import (
	"net"
	"net/http"
	"time"

	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
)

// UpdateRequest 为 HTTP 请求体结构
type UpdateRequest struct {
	Targets    []string `json:"targets,omitempty"` // 可选：目标 Identity 列表
	All        bool     `json:"all,omitempty"`     // 是否推送到所有在线副机
	PackageURL string   `json:"package_url"`       // 更新包下载地址
	Version    string   `json:"version,omitempty"` // 版本号
	Notes      string   `json:"notes,omitempty"`   // 备注
}

type UpdateMessage struct {
	Action     string `json:"action"`
	PackageURL string `json:"package_url,omitempty"`
	Version    string `json:"version,omitempty"`
	Notes      string `json:"notes,omitempty"`
}

// PgProxyItem ✅ 新增：代理配置结构体
type PgProxyItem struct {
	LocalPort  int    `json:"local_port"`  // 本地监听端口 (给pgadmin连)
	TargetIP   string `json:"target_ip"`   // proxy局域网的目标IP
	TargetPort int    `json:"target_port"` // proxy局域网的目标端口
	Comment    string `json:"comment"`
	EnableZip  int    `json:"enable_zip"` // 是否启用压缩传输 (0=否，1=是)
}

type PgProxyConfig struct {
	Mappings []PgProxyItem `json:"mappings"`
}

// VersionedKey ... (VersionedKey, ClientMeta, discoveryNotifee, clientMeta 定义保持不变)
type VersionedKey struct {
	Version int
	KeyData []byte
	Magic   []byte
}

// 新增：通过 Proxy 查询目标 B 的 peer 信息
type vncPeerInfoResp struct {
	PeerID string   `json:"peer_id"`
	Addrs  []string `json:"addrs"`
}

type discoveryNotifee struct {
	h         host.Host
	foundPeer chan peer.AddrInfo
}

// P2PErrorContainer 用于在 Context 中传递 P2P 代理的错误
type P2PErrorContainer struct {
	Err error
}

// StreamConn 包装 network.Stream 以适配 net.Conn 接口
type StreamConn struct {
	network.Stream
}

func (c *StreamConn) LocalAddr() net.Addr {
	return &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1), Port: 0}
}

func (c *StreamConn) RemoteAddr() net.Addr {
	return &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1), Port: 0}
}

func (c *StreamConn) SetDeadline(t time.Time) error {
	return c.Stream.SetDeadline(t)
}

func (c *StreamConn) SetReadDeadline(t time.Time) error {
	return c.Stream.SetReadDeadline(t)
}

func (c *StreamConn) SetWriteDeadline(t time.Time) error {
	return c.Stream.SetWriteDeadline(t)
}

// VNCTargetConfig 新增：VNC 目标配置结构体
type VNCTargetConfig struct {
	Name        string `json:"name,omitempty"` // 配置名称，用于命令行匹配
	UserID      string `json:"user_id"`
	ShopID      string `json:"shop_id"`
	LocalPort   int    `json:"local_port"`
	TargetIP    string `json:"target_ip,omitempty"`    // 可选的目标IP地址，默认为127.0.0.1
	TargetPort  int    `json:"target_port,omitempty"`  // 可选的目标端口，默认为8900
	ConnectType string `json:"connect_type,omitempty"` // 可选的连接类型，默认为 "direct" "proxy" "direct_proxy"
}

// PostgresTargetConfig 新增：PostgreSQL 目标配置结构体
type PostgresTargetConfig struct {
	Name        string `json:"name,omitempty"` // 配置名称，用于命令行匹配
	UserID      string `json:"user_id"`
	ShopID      string `json:"shop_id"`
	LocalPort   int    `json:"local_port"`
	TargetIP    string `json:"target_ip,omitempty"`    // 可选的目标IP地址，默认为127.0.0.1
	TargetPort  int    `json:"target_port,omitempty"`  // 可选的目标端口，默认为5432
	ConnectType string `json:"connect_type,omitempty"` // 可选的连接类型，默认为 "direct" "proxy" "direct_proxy"
}

// StatusRecorder 1. 定义一个包装器，用于捕获状态码
type StatusRecorder struct {
	http.ResponseWriter
	StatusCode int
}

// WriteHeader 重写 WriteHeader 以捕获状态码
func (r *StatusRecorder) WriteHeader(statusCode int) {
	r.StatusCode = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

// (可选) 重写 Write 以确保在没有显式调用 WriteHeader 时默认为 200
func (r *StatusRecorder) Write(b []byte) (int, error) {
	if r.StatusCode == 0 {
		r.StatusCode = http.StatusOK
	}
	return r.ResponseWriter.Write(b)
}

// === 副机连接管理 ===

// ClientConn 副机连接信息结构体
type ClientConn struct {
	Conn     net.Conn
	Identity string // 形如 "user|shop"
	Remote   string // remote addr
	ShopName string
	LastSeen time.Time // 最近心跳时间
	Online   bool      `json:"online"`

	Working       bool      `json:"working"`                  // 是否在执行任务
	Task          string    `json:"task,omitempty"`           // 当前任务名称/描述
	Progress      int       `json:"progress,omitempty"`       // 0-100
	Info          string    `json:"info,omitempty"`           // 任务详细信息或附加信息
	StatusUpdated time.Time `json:"status_updated,omitempty"` // 状态更新时间
}
