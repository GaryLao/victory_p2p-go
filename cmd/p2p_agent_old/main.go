package main

/**
P2P 代理客户端 (p2p_agent)
功能：
1. 主动连接到 p2p_proxy 服务器，建立 P2P 隧道。
2. 提供本地 HTTP 代理服务，允许局域网内其他电脑通过 P2P 隧道访问服务器内容。
3. 支持动态选择目标端口（80 或 8589），通过 URL 参数控制。
4. 实现连接守护，确保与 p2p_proxy 的连接稳定。

*/

import (
	"bufio"
	"bytes"
	"context"
	cryptorand "crypto/rand" // 新增
	"crypto/rsa"             // 新增
	"crypto/tls"             // 新增
	"crypto/x509"            // 新增
	"crypto/x509/pkix"       // 新增
	"database/sql"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"io"
	"log"
	"math/big"
	mathrand "math/rand"
	"net"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"syscall"
	"unsafe"

	"github.com/graphql-go/graphql"
	"github.com/klauspost/compress/snappy"
	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p/core/crypto"
	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/peerstore"
	// "github.com/libp2p/go-libp2p/core/peerstore"
	"github.com/libp2p/go-libp2p/core/protocol"
	"github.com/libp2p/go-libp2p/p2p/host/autorelay"
	rcmgr "github.com/libp2p/go-libp2p/p2p/host/resource-manager"

	// "github.com/libp2p/go-libp2p/p2p/host/autorelay" // ✅ 新增：用于配置静态中继
	"github.com/multiformats/go-multiaddr"
	ma "github.com/multiformats/go-multiaddr"
	"golang.org/x/sys/windows/registry"
	"golang.org/x/text/encoding/simplifiedchinese"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"

	_ "github.com/lib/pq"
)

// ... (常量和结构体定义保持不变)
const (
	AppTitle = "P2P_Agent_Client"
	AppName  = "p2p_agent"

	ProtocolPrefix  = "p2p_proxy"
	ProtocolVersion = "1.0.0"
	P2PProtocol     = "/" + ProtocolPrefix + "/" + ProtocolVersion
	// PingProtocol    = "/ping/" + ProtocolVersion

	// TunnelProtocol 新增：定义隧道协议 ID (必须与服务端一致)
	TunnelProtocol = "/" + ProtocolPrefix + "/tunnel/1.0.0"

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
	AgentClientHttpPort = "9301" // p2p_agent 用于管理主机和副机的 http 接口（比如：查看在线副机和推送更新信息到副机）
	AgentProxyHttpPort  = "9300" // p2p_agent 接收局域网代理 HTTP 请求并转发到云端服务器

	ProxyListenPort = "8590" // p2p_proxy 监听端口

	BkeyFileName = "p2p_proxy.key"
	AkeyFileName = "p2p_agent.key" // 新增常量
)

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

type ClientMeta struct {
	UserID string
	ShopID string
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
	UserID      string `json:"user_id"`
	ShopID      string `json:"shop_id"`
	LocalPort   int    `json:"local_port"`
	TargetIP    string `json:"target_ip,omitempty"`    // 可选的目标IP地址，默认为127.0.0.1
	ConnectType string `json:"connect_type,omitempty"` // 可选的连接类型，默认为 "direct" "proxy" "direct_proxy"
}

// PostgresTargetConfig 新增：PostgreSQL 目标配置结构体
type PostgresTargetConfig struct {
	UserID      string `json:"user_id"`
	ShopID      string `json:"shop_id"`
	LocalPort   int    `json:"local_port"`
	TargetIP    string `json:"target_ip,omitempty"`    // 可选的目标IP地址，默认为127.0.0.1
	ConnectType string `json:"connect_type,omitempty"` // 可选的连接类型，默认为 "direct" "proxy"
}

// ✅ 新增：P2P 失败记忆变量
var (
	lastP2PFailure   time.Time
	lastP2PFailureMu sync.RWMutex
)

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

// SnappyConn 包装 Snappy 流以适配 net.Conn 接口
type SnappyConn struct {
	net.Conn
	r *snappy.Reader
	w *snappy.Writer
}

func NewSnappyConn(c net.Conn) *SnappyConn {
	return &SnappyConn{
		Conn: c,
		r:    snappy.NewReader(c),
		w:    snappy.NewBufferedWriter(c),
	}
}

func (s *SnappyConn) Read(p []byte) (int, error) {
	return s.r.Read(p)
}

func (s *SnappyConn) Write(p []byte) (int, error) {
	n, err := s.w.Write(p)
	if err != nil {
		return n, err
	}
	return n, s.w.Flush() // 必须 Flush 才能发送出去
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

// 全局副机连接表
var (
	clientMu  sync.RWMutex
	clientMap = make(map[string]*ClientConn) // key = Identity 或 remote 地址
)

// UpdateOnline 根据阈值更新 Online 字段（可在写入 LastSeen 后调用）
func (c *ClientConn) UpdateOnline(threshold time.Duration) {
	if c == nil {
		return
	}
	// 明确无连接时直接标记离线，避免覆盖 handleClientConn 已做的离线标记
	if c.Conn == nil {
		c.Online = false
		return
	}

	// 有连接时按 LastSeen 判定（需要在调用者持锁或保证并发安全）
	c.Online = time.Since(c.LastSeen) < threshold
	// log.Printf("ℹ️ 副机 %s 在线状态更新: Online=%v", c.Identity, c.Online)
}

// 获取当前在线副机快照
//
//	func listClientConns() []ClientConn {
//		clientMu.RLock()
//		defer clientMu.RUnlock()
//		out := make([]ClientConn, 0, len(clientMap))
//		for _, v := range clientMap {
//			out = append(out, *v)
//		}
//		return out
//	}
//
// listClientConns 返回当前在线副机快照，并实时计算 Online 字段
func listClientConns() []ClientConn {
	clientMu.RLock()
	defer clientMu.RUnlock()
	out := make([]ClientConn, 0, len(clientMap))
	for _, v := range clientMap {
		// 复制结构，避免外部修改原 map 中对象
		cc := *v
		cc.UpdateOnline(clientOnlineTimeout)
		out = append(out, cc)
	}
	return out
}

// 可选：把 handleClientConn 中的离线标记封装成函数，便于复用和保持锁一致性
func markClientOffline(key, remote string) {
	clientMu.Lock()
	defer clientMu.Unlock()

	if cur, ok := clientMap[key]; ok {
		cur.Conn = nil
		cur.LastSeen = time.Now()
		cur.Remote = remote
		cur.Online = false
		cur.Info = ""
		clientMap[key] = cur
		return
	}

	clientMap[key] = &ClientConn{
		Conn:     nil,
		Identity: key,
		Remote:   remote,
		ShopName: "",
		LastSeen: time.Now(),
		Online:   false,
		Info:     "",
	}
}

// dedupeClientMapByIdentityPrefix 按 Identity 的前缀（第一个 '|' 之前部分）去重。
// 对同一前缀，保留时间戳（Identity 第三段）或 LastSeen 最新的一条，关闭并删除其余条目。
func dedupeClientMapByIdentityPrefix() {
	clientMu.Lock()
	defer clientMu.Unlock()

	type candidate struct {
		key string
		t   time.Time
	}

	best := make(map[string]candidate) // prefix -> best key & time

	for key, cc := range clientMap {
		prefix := cc.Identity
		if idx := strings.Index(prefix, "|"); idx >= 0 {
			prefix = prefix[:idx]
		}
		var t time.Time
		// ts, ok := parseIdentityTimestamp(cc.Identity)
		// if ok {
		// 	t = ts
		// } else {
		// 	t = cc.LastSeen
		// }
		t = cc.LastSeen
		cur, found := best[prefix]
		if !found || t.After(cur.t) {
			best[prefix] = candidate{key: key, t: t}
		}
	}

	// 删除非最佳的条目
	for key, cc := range clientMap {
		prefix := cc.Identity
		if idx := strings.Index(prefix, "|"); idx >= 0 {
			prefix = prefix[:idx]
		}
		if chosen, ok := best[prefix]; ok && chosen.key != key {
			if clientMap[key] != nil && clientMap[key].Conn != nil {
				_ = clientMap[key].Conn.Close()
			}
			delete(clientMap, key)
			log.Printf("🗑️ 已移除重复副机: key=%s prefix=%s，仅保留=%s", key, prefix, chosen.key)
		}
	}
}

// parseIdentityTimestamp 从 Identity（格式可能为 prefix|ips|20251225_034205）解析第三段时间戳。
// 第三段代表副机 client.exe 的修改时间，支持格式 "20060102_150405" 和 "20060102"。
// 返回解析后的 time.Time 和是否成功解析。
func parseIdentityTimestamp(identity string) (time.Time, bool) {
	parts := strings.Split(identity, "|")
	if len(parts) < 3 {
		return time.Time{}, false
	}
	ts := parts[2]
	if ts == "" {
		return time.Time{}, false
	}
	if t, err := time.Parse("20060102_150405", ts); err == nil {
		return t, true
	}
	if t, err := time.Parse("20060102", ts); err == nil {
		return t, true
	}
	return time.Time{}, false
}

// 非阻塞尝试发送，立即返回是否发送成功
func trySendNonBlocking(ch chan string, val string) bool {
	select {
	case ch <- val:
		return true // 已成功发送（或写入缓冲区）
	default:
		return false // 无法立即发送，已放弃
	}
}

// 带超时尝试发送（更稳妥，最多等待 timeout）
func trySendWithTimeout(ch chan string, val string, timeout time.Duration) bool {
	timer := time.NewTimer(timeout)
	defer timer.Stop()
	select {
	case ch <- val:
		return true
	case <-timer.C:
		return false // 超时，放弃
	}
}

// 在独立协程发送，避免阻塞当前协程（可能会阻塞新协程直到发送完成）
func sendInGoroutine(ch chan string, val string) {
	go func() {
		ch <- val // 可能阻塞，直到有接收方或缓冲可用
	}()
}

// 打印当前在线副机
func printClientConns() {
	conns := listClientConns()
	for _, c := range conns {
		log.Printf("副机消息: Identity=%s Remote=%s LastSeen=%s",
			c.Identity, c.Remote, c.LastSeen.Format(time.RFC3339))
	}
}

// 暴露一个简单的 HTTP JSON 接口，返回在线副机快照
func clientHandler(w http.ResponseWriter, r *http.Request) {
	conns := listClientConns()
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	if err := json.NewEncoder(w).Encode(conns); err != nil {
		http.Error(w, "encode error", http.StatusInternalServerError)
		return
	}
}

// 清理副机超时连接（直接操作全局 clientMap，需要使用 clientMu）
func cleanupInactive(threshold time.Duration) {
	cutoff := time.Now().Add(-threshold)
	clientMu.Lock()
	defer clientMu.Unlock()
	for k, v := range clientMap {
		if v == nil {
			delete(clientMap, k)
			continue
		}
		if v.LastSeen.Before(cutoff) {
			_ = v.Conn.Close() // 关闭连接
			delete(clientMap, k)
			log.Printf("移除不活跃的副机: %s", k)
		}
	}
}

func startHostConnector(host, port string) {
	addr := net.JoinHostPort(host, port)
	// 初始退避
	baseDelay := 2 * time.Second
	maxDelay := 60 * time.Second
	for {
		conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
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
		idLine := fmt.Sprintf("%s-%s\n", shopid, pcid)
		if _, err := conn.Write([]byte(idLine)); err != nil {
			log.Printf("❌ 发送身份失败: %v", err)
			conn.Close()
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
				if line != "" {
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
		conn.Close()
		// 小延迟后重连（避免忙循环）
		time.Sleep(1 * time.Second)
	}
}

// === 副机连接管理结束 ===

// 新增：设置控制台标题的辅助函数
func setConsoleTitle(title string) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procSetConsoleTitle := kernel32.NewProc("SetConsoleTitleW")
	utf16Title, _ := syscall.UTF16PtrFromString(title)
	procSetConsoleTitle.Call(uintptr(unsafe.Pointer(utf16Title)))
}

func init() {
	log.Printf("🚀 " + AppName + " 启动中...........................................................")

	// 密钥生成逻辑已移动到 loadServerAKey 中，以支持动态文件名

	// 在 init 函数中解析命令行参数
	flag.StringVar(&adverserIPFlag, "advip", "", "指定 p2p_proxy 的 IP 地址")
	// 注意：flag.Parse() 应该在 main 函数开始时调用，
	// 但由于这个 init 函数会在 main 之前执行，
	// 所以我们不在这里调用 flag.Parse()

	// 解析命令行参数
	flag.Parse()

	// 从配置文件加载 p2p_proxy 地址
	AdverserDomain = loadAdverserDomain()
	if AdverserDomain == "" {
		AdverserDomain = "shop.4080517.com"
	}

	// 优先判断是否运行在“服务器”还是“副机”
	SupertouchPCDataIP = getSupertouchPCDataIP()

	isLocalServer = isLocalIPAddress(SupertouchPCDataIP)
	if isLocalServer {
		// 视为服务器：使用配置或回退 IP
		AdverserIp = loadAdverserIP()
	} else {
		// 视为副机：使用主机上配置的 Data IP（副机地址）
		AdverserIp = SupertouchPCDataIP
	}

	if AdverserIp == "" {
		AdverserIp = "123.57.163.15"
	}
	// 用于测试域名
	// AdverserIp = "www.400800517.com"

	// ADVERSER = "/ip4/" + AdverserIp + "/tcp/8590" // p2p_proxy 地址
	// === 修改开始：自动识别 IP 或域名 ===
	proto := "/ip4/"
	// 如果 ParseIP 返回 nil，说明不是合法的 IP 字符串，则认为是域名
	if net.ParseIP(AdverserIp) == nil {
		proto = "/dns4/"
	}
	ADVERSER = proto + AdverserIp + "/tcp/" + ProxyListenPort // p2p_proxy 地址
	// === 修改结束 ===

	// 在这里添加日志
	log.Printf("🌍 p2p_proxy 默认域名: %s", AdverserDomain)
	log.Printf("🔗 p2p_proxy 回退地址: %s", ADVERSER)

	// 定义简单的 Schema (示例：Hello World)
	// 你可以在这里扩展更多字段，例如连接数据库查询
	fields := graphql.Fields{
		"hello": &graphql.Field{
			Type: graphql.String,
			Resolve: func(p graphql.ResolveParams) (interface{}, error) {
				return "world", nil
			},
		},
		// 示例：添加一个回显字段
		"echo": &graphql.Field{
			Type: graphql.String,
			Args: graphql.FieldConfigArgument{
				"msg": &graphql.ArgumentConfig{Type: graphql.String},
			},
			Resolve: func(p graphql.ResolveParams) (interface{}, error) {
				msg, _ := p.Args["msg"].(string)
				return msg, nil
			},
		},
		// 新增：通用数据库查询 (SELECT) -> 返回 JSON 字符串
		// 示例 query: { db_query(sql: "SELECT * FROM some_table LIMIT 10") }
		"db_query": &graphql.Field{
			Type: graphql.String,
			Args: graphql.FieldConfigArgument{
				"sql": &graphql.ArgumentConfig{Type: graphql.NewNonNull(graphql.String)},
			},
			Resolve: func(p graphql.ResolveParams) (interface{}, error) {
				sqlStr, _ := p.Args["sql"].(string)

				// 连接数据库 (使用 handleGetBillLog 中的配置)
				connStr := "postgres://sysdba:masterkey@localhost/victorysvr?sslmode=disable"
				db, err := sql.Open("postgres", connStr)
				if err != nil {
					return nil, fmt.Errorf("DB连接失败: %v", err)
				}
				defer db.Close()

				rows, err := db.Query(sqlStr)
				if err != nil {
					return nil, fmt.Errorf("SQL查询失败: %v", err)
				}
				defer rows.Close()

				// 复用 rowsToJSON 将结果转换为 JSON 字符串
				jsonBytes, err := rowsToJSON(rows)
				if err != nil {
					return nil, fmt.Errorf("结果转换失败: %v", err)
				}
				return string(jsonBytes), nil
			},
		},
		// 新增：通用数据库执行 (INSERT/UPDATE/DELETE) -> 返回受影响行数
		// 示例 mutation: { db_exec(sql: "UPDATE some_table SET col=1 WHERE id=1") }
		// 注意：虽然是修改操作，但在 graphql-go 中为了简化配置，这里暂时挂载在 Query 下，
		// 规范做法是挂载在 Mutation 下，但效果是一样的。
		"db_exec": &graphql.Field{
			Type: graphql.Int,
			Args: graphql.FieldConfigArgument{
				"sql": &graphql.ArgumentConfig{Type: graphql.NewNonNull(graphql.String)},
			},
			Resolve: func(p graphql.ResolveParams) (interface{}, error) {
				sqlStr, _ := p.Args["sql"].(string)

				connStr := "postgres://sysdba:masterkey@localhost/victorysvr?sslmode=disable"
				db, err := sql.Open("postgres", connStr)
				if err != nil {
					return nil, fmt.Errorf("DB连接失败: %v", err)
				}
				defer db.Close()

				res, err := db.Exec(sqlStr)
				if err != nil {
					return nil, fmt.Errorf("SQL执行失败: %v", err)
				}

				affected, err := res.RowsAffected()
				if err != nil {
					return 0, nil
				}
				return int(affected), nil
			},
		},
	}

	rootQuery := graphql.ObjectConfig{Name: "RootQuery", Fields: fields}
	schemaConfig := graphql.SchemaConfig{Query: graphql.NewObject(rootQuery)}

	var err error
	p2pSchema, err = graphql.NewSchema(schemaConfig)
	if err != nil {
		log.Fatalf("❌ 致命错误：GraphQL Schema 初始化失败: %v", err)
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

	// 构造静态中继节点信息
	proxyAddrInfo := peer.AddrInfo{
		ID:    serverBID,
		Addrs: []multiaddr.Multiaddr{proxyMultiAddr},
	}

	// 资源管理器
	limiter := rcmgr.NewFixedLimiter(rcmgr.InfiniteLimits)
	rm, err := rcmgr.NewResourceManager(limiter)
	if err != nil {
		log.Fatalf("致命错误：创建资源管理器失败: %v", err)
	}

	h, err := libp2p.New(
		libp2p.Identity(loadServerAKey()), // 使用 p2p_agent 自己的密钥

		// // libp2p.NoListenAddrs, // 客户端模式：不监听地址
		libp2p.ListenAddrStrings("/ip4/0.0.0.0/tcp/0"), // ✅ 改为：监听随机端口 (打洞必须)

		libp2p.Ping(true), // 启用内置心跳机制 // 注册了 `/ping/1.0.0` 协议
		// // libp2p.NATPortMap(), // 可选：NAT穿透

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

		// [可选] 强制声明为私有网络
		// 如果确定 Agent 都在内网，这会强制它立即寻找中继，而不是尝试公网监听
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

	// 移到上面
	// // 加载 p2p_proxy 的密钥并生成 Peer ID
	// privKey := loadServerBKey()
	// pubKey := privKey.GetPublic()
	// serverBID, err := peer.IDFromPublicKey(pubKey)
	// if err != nil {
	// 	log.Fatalf("无法生成 Peer ID: %v", err)
	// }
	// log.Printf("p2p_proxy Peer ID: %s", serverBID)

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
	if targets, err := loadVNCTargets(); err == nil {
		log.Printf("📂 已加载 %d 个 VNC 目标配置", len(targets))
		for _, t := range targets {
			// log.Printf("🔗 启动 VNC 客户端: UserID=%s ShopID=%s LocalPort=%d TargetIP=%s ConnectType=%s", t.UserID, t.ShopID, t.LocalPort, t.TargetIP, t.ConnectType)
			if ("" == t.ConnectType) || ("proxy" == t.ConnectType) {
				go startVNCClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP)
			} else if "direct" == t.ConnectType {
				go startVNCP2PClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP)
			} else if "direct_proxy" == t.ConnectType {
				go startVNCP2PRelayClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP)
			}
		}
	} else {
		log.Printf("ℹ️ 未检测到 VNC 配置文件 (vnc_targets.json) 或解析失败，跳过 VNC 客户端启动: %v", err)
	}

	// 新增：加载 PostgreSQL 目标配置并启动监听
	if pgTargets, err := loadPostgresTargets(); err == nil {
		for _, t := range pgTargets {
			if ("" == t.ConnectType) || ("proxy" == t.ConnectType) {
				go startPostgresClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP)
			} else if "direct" == t.ConnectType {
				go startPostgresP2PClient(ctx, h, serverBID, t.UserID, t.ShopID, t.LocalPort, t.TargetIP)
			}
		}
	} else {
		log.Printf("ℹ️ 未检测到 VNC 配置文件 (pg_targets.json) 或解析失败，跳过 PG 客户端启动: %v", err)
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
	// go startActiveStream(ctx, h, serverBID)

	return h, serverBID
}

func main() {
	// 1. 初始化日志 (按日保存，保留10个)
	setupLog() // ✅ 新增

	// 单实例运行检查
	checkSingleton()

	// 2. 设置窗口标题 (用于 p2p_monitor 识别)
	setConsoleTitle(AppTitle)

	// log.Printf("启动参数: isLocalServer=%v SupertouchPCDataIP=%s AdverserIp=%s AdverserDomain=%s", isLocalServer, SupertouchPCDataIP, AdverserIp, AdverserDomain)

	// log.Printf("🚀 " + AppName + " 启动中-------------------------------------------------------")

	if isLocalServer {
		// === 局域网的主机逻辑 (p2p_agent)，需要连接到云端服务器 ===

		// 启动本机作为“主机”的处理逻辑
		h, _ := startAgentHostServices()
		// 在 main 中延迟关闭 host（程序退出时执行）
		defer func() {
			if h != nil {
				_ = h.Close()
			}
		}()

		// 启动副机监听服务（在服务端启动）和副机管理逻辑
		startClientManager()

		log.Printf("✅ " + AppName + " 启动完成，正在运行中...")

		// 阻塞主线程，防止程序退出
		select {}
	} else {
		// === 局域网的副机 (p2p_agent)，需要连接到局域网的 p2p_agent ===
		// go startHostConnector(SupertouchPCDataIP, AgentClientsidePort)
	}

}

// === 新增：单实例检查函数 ===
func checkSingleton() {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procCreateMutex := kernel32.NewProc("CreateMutexW")

	// 定义互斥体名称 (使用 Global 前缀跨会话，或 Local 前缀仅限当前会话)
	// 建议使用 Global 以防止不同用户或服务同时运行
	mutexName := "Global\\P2P_Agent_Singleton_Mutex"
	namePtr, _ := syscall.UTF16PtrFromString(mutexName)

	// 调用 CreateMutexW(lpMutexAttributes, bInitialOwner, lpName)
	// 返回值 handle 如果非 0 表示创建成功或获取了已存在的句柄
	handle, _, err := procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(namePtr)))

	// 如果 Global 创建失败（可能是权限问题），尝试降级到 Local
	if handle == 0 {
		mutexName = "Local\\P2P_Agent_Singleton_Mutex"
		namePtr, _ = syscall.UTF16PtrFromString(mutexName)
		handle, _, err = procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(namePtr)))
	}

	if handle == 0 {
		log.Printf("⚠️ 无法创建互斥体，无法保证单实例运行: %v", err)
		return
	}

	// 检查错误代码：ERROR_ALREADY_EXISTS = 183
	if err == syscall.Errno(183) {
		log.Printf("⚠️ 程序实例已在运行中，本实例即将退出...")
		time.Sleep(1 * time.Second) // 等待日志写入
		os.Exit(0)
	}

	// 注意：不要调用 CloseHandle(handle)，我们需要让这个句柄在进程生命周期内一直存在。
	// 操作系统会在进程结束时自动释放它。
}

func loadAdverserIP() string {
	// log.Printf("🔍 正在加载 p2p_proxy 回退 IP 地址 %s", adverserIPFlag)
	// 1. 检查命令行参数
	if adverserIPFlag != "" {
		return adverserIPFlag
	}

	// 2. 回退到从配置文件加载
	custom := filepath.Join("Data", "database_custom.ini")
	defaultIni := filepath.Join("Data", "database.ini")

	// WebChat_IP 字段存储的其实是 IP 地址
	// WebChat_ServerIP 字段存储的其实是域名
	// defaultIni 由于历史原因，只有 WebChat_ServerIP
	if ip := getIniValue(custom, "TransferFileToHeadSvr", "WebChat_IP"); ip != "" {
		return ip
	}
	return getIniValue(defaultIni, "TransferFileToHeadSvr", "WebChat_ServerIP")
}

func loadAdverserDomain() string {
	// 1. 检查命令行参数
	if adverserIPFlag != "" {
		return adverserIPFlag
	}

	custom := filepath.Join("Data", "database_custom.ini")
	defaultIni := filepath.Join("Data", "database.ini")
	// log.Printf("%s", custom)
	// log.Printf("%s", defaultIni)

	// WebChat_ServerIP 字段存储的其实是域名
	if serverDomain := getIniValue(custom, "TransferFileToHeadSvr", "WebChat_ServerIP"); serverDomain != "" {
		return serverDomain
	}
	return getIniValue(defaultIni, "TransferFileToHeadSvr", "WebChat_ServerIP")
}

func getIniValue(path, section, key string) string {
	file, err := os.Open(path)
	if err != nil {
		return ""
	}
	defer file.Close()

	section = strings.ToLower(section)
	key = strings.ToLower(key)

	scanner := bufio.NewScanner(file)
	currentSection := ""

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, ";") || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			currentSection = strings.ToLower(strings.Trim(line, "[]"))
			continue
		}
		if currentSection == section {
			if idx := strings.Index(line, "="); idx > 0 {
				k := strings.ToLower(strings.TrimSpace(line[:idx]))
				if k == key {
					return strings.TrimSpace(line[idx+1:])
				}
			}
		}
	}

	return ""
}

func getExecutableName() string {
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("⚠️ 无法获取可执行文件路径: %v", err)
		return AppName
	}
	return strings.TrimSuffix(filepath.Base(exePath), filepath.Ext(exePath))
}

// === 日志轮转逻辑 ===

// setupLog 初始化日志配置
func setupLog() {
	logDir := "log"
	// 创建日志目录
	_ = os.MkdirAll(logDir, 0755)

	// 创建自定义 Writer
	rotator := &DailyLogWriter{
		Dir:      logDir,
		MaxFiles: 20,
	}

	// 立即初始化当天的文件
	rotator.rotate(time.Now().Format("2006-01-02"))

	// 设置 log 输出：同时写入 控制台(Stdout) 和 文件(rotator)
	log.SetOutput(io.MultiWriter(os.Stdout, rotator))

	// 可选：设置日志格式 (日期 时间 文件:行号)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
}

// DailyLogWriter 实现按日轮转的日志写入器
type DailyLogWriter struct {
	Dir      string
	MaxFiles int
	file     *os.File
	date     string
	mu       sync.Mutex
}

// Write 实现 io.Writer 接口
func (w *DailyLogWriter) Write(p []byte) (n int, err error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	// 检查日期是否变更
	today := time.Now().Format("2006-01-02")
	if today != w.date {
		w.rotate(today)
	}

	// 写入文件
	if w.file != nil {
		return w.file.Write(p)
	}
	return len(p), nil
}

// rotate 轮转日志文件
func (w *DailyLogWriter) rotate(today string) {
	// 关闭旧文件
	if w.file != nil {
		w.file.Close()
	}

	// 获取当前可执行文件名前缀 (getExecutableName 已返回无后缀的文件名)
	exeName := getExecutableName()
	filename := filepath.Join(w.Dir, exeName+"_"+today+".log")
	// 打开新文件 (追加模式)
	f, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil {
		w.file = f
		w.date = today
		// 清理旧文件
		w.cleanup()
	} else {
		// 如果打开失败，打印错误到控制台（避免递归调用 log）
		os.Stdout.WriteString(fmt.Sprintf("❌ 无法打开日志文件: %v\n", err))
		w.file = nil
	}
}

// cleanup 清理多余的日志文件
func (w *DailyLogWriter) cleanup() {
	entries, err := os.ReadDir(w.Dir)
	if err != nil {
		return
	}

	// 获取当前可执行文件名前缀 (getExecutableName 已返回无后缀的文件名)
	exeName := getExecutableName()
	prefix := exeName + "_"
	suffix := ".log"

	// 收集符合条件的日志文件
	var logs []string
	for _, e := range entries {
		// if !e.IsDir() && strings.HasPrefix(e.Name(), prefix) && strings.HasSuffix(e.Name(), ".log") {
		// 	logs = append(logs, filepath.Join(w.Dir, e.Name()))
		// }
		if e.IsDir() {
			continue
		}

		name := e.Name()

		// 1. 基础匹配：检查前缀和后缀
		if !strings.HasPrefix(name, prefix) || !strings.HasSuffix(name, suffix) {
			continue
		}

		// 2. 严格匹配：提取中间部分并验证是否为日期格式 (YYYY-MM-DD)
		// 这一步至关重要，防止误删如 p2p_agent_error.log 等非轮转日志
		datePart := name[len(prefix) : len(name)-len(suffix)]
		if _, err := time.Parse("2006-01-02", datePart); err != nil {
			continue
		}

		logs = append(logs, filepath.Join(w.Dir, name))
	}

	// os.ReadDir 返回的文件已按文件名排序 (YYYY-MM-DD 格式天然有序)
	// 如果文件数超过限制，删除最旧的
	if len(logs) > w.MaxFiles {
		removeCount := len(logs) - w.MaxFiles
		for i := 0; i < removeCount; i++ {
			err := os.Remove(logs[i])
			if err != nil {
				os.Stdout.WriteString(fmt.Sprintf("⚠️ 删除旧日志失败: %v\n", err))
			} else {
				os.Stdout.WriteString(fmt.Sprintf("🗑️ 已清理旧日志: %s\n", logs[i]))
			}
		}
	}
}

// 新增：加载 PostgreSQL 配置文件
func loadPostgresTargets() ([]PostgresTargetConfig, error) {
	file, err := os.Open("pg_targets.json")
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var targets []PostgresTargetConfig
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&targets); err != nil {
		return nil, fmt.Errorf("JSON 解析失败: %v", err)
	}
	return targets, nil
}

// 新增：被控端处理 -> 连接本地 PostgreSQL (5432)
func handlePostgresConnection(s network.Stream) {
	defer s.Close()
	log.Printf("📥 收到 PostgreSQL 远程连接请求")

	reader := bufio.NewReader(s)

	// // 1. 读取第一行获取目标身份信息 (user_id|shopid\n)
	// _, err := reader.ReadString('\n')
	// if err != nil {
	// 	log.Printf("❌ 读取VNC目标身份信息失败: %v", err)
	// 	return
	// }
	// // 注意：此处读取到的身份信息未被进一步使用，但必须读取以消耗缓冲区内容

	// 2. 读取第二行获取目标IP地址（如果提供了的话）
	ipLine, err := reader.ReadString('\n')
	if err != nil {
		log.Printf("❌ 读取VNC目标信息失败: %v", err)
		return
	}

	targetIP := strings.TrimSpace(ipLine)
	if targetIP == "" {
		targetIP = "127.0.0.1" // 默认值
	}

	// 动态获取 PostgreSQL 端口
	port := getPostgresPortFromConf()

	// 连接本地 PostgreSQL
	pgConn, err := net.Dial("tcp", targetIP+":"+port)
	if err != nil {
		log.Printf("❌ 无法连接本地 PostgreSQL (%s): %v", port, err)
		return
	}
	defer pgConn.Close()

	go io.Copy(pgConn, s)
	io.Copy(s, pgConn)
}

// 新增：控制端处理 -> 启动本地监听 -> 转发给 Proxy (PG Relay)
func startPostgresClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string) {
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", localPort))
	if err != nil {
		log.Printf("❌ PG 客户端监听失败 (端口 %d): %v", localPort, err)
		return
	}
	log.Printf("🐘 PG 中继启动: 本地 :%d -> 远程 %s_%s (PostgreSQL)", localPort, targetUser, targetShop)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("PG Accept error: %v", err)
			continue
		}

		go func(c net.Conn) {
			defer c.Close()

			// 1. 连接 Proxy (使用 PG Relay 协议)
			s, err := h.NewStream(ctx, proxyPID, PostgresRelayProtocol)
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

			// 4. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
			// 这里可以根据配置或者参数传递实际的IP地址
			postgresIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
			if targetIP != "" {
				postgresIP = targetIP
			}
			if _, err := s.Write([]byte(postgresIP + "\n")); err != nil {
				log.Printf("❌ [Postgres] 发送目标IP地址失败: %v", err)
				return
			}

			// 3. 双向转发
			go io.Copy(s, c)
			io.Copy(c, s)
		}(conn)
	}
}

func startPostgresP2PClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string) {
	listenAddr := fmt.Sprintf(":%d", localPort)
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		log.Printf("❌ PG 客户端监听失败 (端口 %d): %v", localPort, err)
		return
	}
	defer listener.Close()

	log.Printf("🐘 PG 监听启动: 本地 :%d -> 远程 %s_%s (P2P)", localPort, targetUser, targetShop)

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

			// 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
			// 这里可以根据配置或者参数传递实际的IP地址
			vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
			if targetIP != "" {
				vncIP = targetIP
			}
			if _, err := s.Write([]byte(vncIP + "\n")); err != nil {
				log.Printf("❌ [PG] 发送目标IP地址失败: %v", err)
				s.Reset()
				return
			}

			log.Printf("✅ [PG] 通道建立成功，开始转发数据")

			// 4. 双向数据转发 (稳健模式)
			var wg sync.WaitGroup
			wg.Add(2)

			// Viewer -> P2P Agent
			go func() {
				defer wg.Done()
				_, _ = io.Copy(s, c)
				s.CloseWrite() // 告诉远程 Agent 我们发完了
			}()

			// P2P Agent -> Viewer
			go func() {
				defer wg.Done()
				_, _ = io.Copy(c, s)
				// 尝试关闭本地 TCP 的写端，触发 Viewer 的 EOF
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				} else {
					_ = c.Close()
				}
			}()

			wg.Wait()
			log.Printf("👋 [PG] 会话结束")

		}(conn)
	}
}

// 新增：加载 VNC 目标配置函数
func loadVNCTargets() ([]VNCTargetConfig, error) {
	file, err := os.Open("vnc_targets.json")
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var targets []VNCTargetConfig
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&targets); err != nil {
		return nil, fmt.Errorf("JSON 解析失败: %v", err)
	}
	return targets, nil
}

// 被控端处理：接收 P2P 请求 -> 转发给本地 UltraVNC (8900)
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

	targetIP := strings.TrimSpace(ipLine)
	log.Printf("🔍 目标 VNC 服务器 IP 地址: %s", targetIP)
	if targetIP == "" {
		targetIP = "127.0.0.1" // 默认值
	}

	// 动态获取 VNC 端口
	port := getVNCPortFromIni()
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
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		io.Copy(conn, s) // P2P -> Local VNC
		if tcpConn, ok := conn.(*net.TCPConn); ok {
			tcpConn.CloseWrite()
		}
	}()

	go func() {
		defer wg.Done()
		io.Copy(s, conn) // Local VNC -> P2P
		s.CloseWrite()
	}()

	wg.Wait()
	// log.Printf("👋 [Target] VNC 会话结束")

}

// startVNCClient [稳定版] 纯中继模式
// 逻辑：本地监听 -> 连接 Proxy (VNCRelayProtocol) -> 告诉 Proxy 目标是谁 -> Proxy 转发给目标
// 优点：极其稳定，无视 NAT 类型，连接建立速度快（无需打洞等待）
func startVNCClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string) {
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

			// 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
			// 这里可以根据配置或者参数传递实际的IP地址
			vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
			if targetIP != "" {
				vncIP = targetIP
			}
			if _, err := stream.Write([]byte(vncIP + "\n")); err != nil {
				log.Printf("❌ [VNC] 发送目标IP地址失败: %v", err)
				return
			}

			log.Printf("✅ [VNC] 隧道建立成功，开始转发数据 (Relay Mode)")

			// 4. 双向数据转发 (使用 WaitGroup 确保双向都关闭)
			var wg sync.WaitGroup
			wg.Add(2)

			// 本地 Viewer -> Proxy
			go func() {
				defer wg.Done()
				_, _ = io.Copy(stream, c)
				// 告诉 Proxy 我发完了 (关闭写端)
				stream.CloseWrite()
			}()

			// Proxy -> 本地 Viewer
			go func() {
				defer wg.Done()
				_, _ = io.Copy(c, stream)
				// 收到 Proxy 的 EOF，关闭本地连接
				// c.Close() // defer 会处理
			}()

			wg.Wait()
			log.Printf("👋 [VNC] 会话结束")

		}(conn)
	}
}

// ✅ 修复版：顺序模式 (P2P -> Relay)
// 彻底解决"竞速模式"导致的双重连接和 VNC Server 封禁问题
func startVNCP2PRelayClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string) {
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
					log.Printf("🔍 [VNC] 尝试 P2P 打洞连接目标 %s (地址数: %d)...", targetInfo.ID.ShortString(), len(targetInfo.Addrs))

					// / 💡 修改：将超时时间从 2秒 增加到 10秒
					// NAT 打洞涉及中继协商和多次握手，2秒通常不足以完成
					connCtx, cancelConn := context.WithTimeout(ctx, 10*time.Second)

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
					s, streamErr := h.NewStream(ctx, targetInfo.ID, protocol.ID(VNCTargetProtocol))
					if streamErr == nil {
						log.Printf("🚀 [VNC] P2P 直连成功")
						targetStream = s
					} else {
						// 这里是流建立失败的关键日志 (例如协议不匹配)
						log.Printf("⚠️ [VNC] P2P 流建立失败: %v", streamErr)
					}

					// 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
					// 这里可以根据配置或者参数传递实际的IP地址
					vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
					if targetIP != "" {
						vncIP = targetIP
					}
					if _, err := s.Write([]byte(vncIP + "\n")); err != nil {
						log.Printf("❌ [VNC] 发送目标IP地址失败: %v", err)
						s.Close()
						return
					}

				} else {
					log.Printf("⚠️ [VNC] P2P 最终未连接，无法打开流")
				}
			}

			// =============================================================
			// 步骤 2: 如果 P2P 失败，立即降级到 Relay (中继)
			// =============================================================
			if targetStream == nil {
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

				// 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
				// 这里可以根据配置或者参数传递实际的IP地址
				vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
				if targetIP != "" {
					vncIP = targetIP
				}
				if _, err := s.Write([]byte(vncIP + "\n")); err != nil {
					log.Printf("❌ [VNC] 发送目标IP地址失败: %v", err)
					s.Close()
					return
				}

				targetStream = s
			}

			log.Printf("✅ [VNC] 隧道建立成功，开始转发数据 (P2P/Relay Mode)")

			// =============================================================
			// 步骤 3: 双向数据转发
			// =============================================================

			// defer targetStream.Close()
			//
			// // 使用 io.Copy 进行双向转发
			// go io.Copy(targetStream, c)
			// io.Copy(c, targetStream)

			// 4. 双向数据转发 (使用 WaitGroup 确保双向都关闭)
			var wg sync.WaitGroup
			wg.Add(2)

			// 本地 Viewer -> Proxy
			go func() {
				defer wg.Done()
				_, _ = io.Copy(targetStream, c)
				// 告诉 Proxy 我发完了 (关闭写端)
				targetStream.CloseWrite()
			}()

			// Proxy -> 本地 Viewer
			go func() {
				defer wg.Done()
				_, _ = io.Copy(c, targetStream)
				// 收到 Proxy 的 EOF，关闭本地连接
				// c.Close() // defer 会处理
			}()

			wg.Wait()
			log.Printf("👋 [VNC] 会话结束")

		}(localConn)
	}
}

// startVNCP2PClient 控制端处理：启动本地监听 -> 优先尝试 P2P 直连
// 优化：复用 P2P 连接，避免每次重连都进行打洞
func startVNCP2PClient(ctx context.Context, h host.Host, proxyPID peer.ID, targetUser, targetShop string, localPort int, targetIP string) {
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

			// 3. 打开数据流
			s, err := h.NewStream(ctx, targetPeerID, protocol.ID(VNCTargetProtocol))
			if err != nil {
				log.Printf("❌ [VNC] 打开数据流失败: %v", err)
				// 如果复用失败（例如连接假死），清除缓存，下次强制重连
				if useCached {
					cachedTargetPeerID = ""
				}
				return
			}
			defer s.Close()

			// 2. 发送目标VNC服务器的IP地址（如果是远程VNC服务器）
			// 这里可以根据配置或者参数传递实际的IP地址
			vncIP := "127.0.0.1" // 默认值，可以通过配置等方式更改
			if targetIP != "" {
				vncIP = targetIP
			}
			if _, err := s.Write([]byte(vncIP + "\n")); err != nil {
				log.Printf("❌ [VNC] 发送目标IP地址失败: %v", err)
				s.Reset()
				return
			}

			log.Printf("✅ [VNC] 通道建立成功，开始转发数据")

			// 4. 双向数据转发 (稳健模式)
			var wg sync.WaitGroup
			wg.Add(2)

			// Viewer -> P2P Agent
			go func() {
				defer wg.Done()
				_, _ = io.Copy(s, c)
				s.CloseWrite() // 告诉远程 Agent 我们发完了
			}()

			// P2P Agent -> Viewer
			go func() {
				defer wg.Done()
				_, _ = io.Copy(c, s)
				// 尝试关闭本地 TCP 的写端，触发 Viewer 的 EOF
				if tcpConn, ok := c.(*net.TCPConn); ok {
					_ = tcpConn.CloseWrite()
				} else {
					_ = c.Close()
				}
			}()

			wg.Wait()
			log.Printf("👋 [VNC] 会话结束")

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

// 辅助函数：判断是否是中继连接
func isRelayConn(m multiaddr.Multiaddr) bool {
	// 简单判断地址中是否包含 p2p-circuit
	for _, p := range m.Protocols() {
		if p.Code == multiaddr.P_CIRCUIT {
			return true
		}
	}
	return false
}

// === 辅助结构体：用于端口复用 (HTTP/HTTPS) ===

// peekConn 包装 net.Conn，允许“偷看”第一个字节后放回
type peekConn struct {
	net.Conn
	peeked []byte
}

func (c *peekConn) Read(p []byte) (n int, err error) {
	if len(c.peeked) > 0 {
		n = copy(p, c.peeked)
		c.peeked = c.peeked[n:]
		return n, nil
	}
	return c.Conn.Read(p)
}

// switchListener 是一个虚拟 Listener，从 channel 接收连接
type switchListener struct {
	net.Listener
	ch chan net.Conn
}

func (l *switchListener) Accept() (net.Conn, error) {
	c, ok := <-l.ch
	if !ok {
		return nil, fmt.Errorf("listener closed")
	}
	return c, nil
}

// generateSelfSignedCert 生成内存中的自签名证书
func generateSelfSignedCert() (tls.Certificate, error) {
	priv, err := rsa.GenerateKey(cryptorand.Reader, 2048)
	if err != nil {
		return tls.Certificate{}, err
	}

	template := x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject: pkix.Name{
			Organization: []string{"P2P Agent"},
		},
		NotBefore: time.Now(),
		NotAfter:  time.Now().Add(365 * 24 * time.Hour),

		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
	}

	derBytes, err := x509.CreateCertificate(cryptorand.Reader, &template, &template, &priv.PublicKey, priv)
	if err != nil {
		return tls.Certificate{}, err
	}

	certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: derBytes})
	keyPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(priv)})

	return tls.X509KeyPair(certPEM, keyPEM)
}

// 修改：接收 host 和 serverPID 参数
func startLocalHttpProxy(h host.Host, serverPID peer.ID) {
	// === 1. 记录启动时间 (用于宽限期计算) ===
	// startTime := time.Now()
	// ======================================

	// lzm common 2025-12-16 16:57:31
	// targetDomain := "shop.4080517.com"

	log.Printf("✅ P2P Socket 代理启动: :"+AgentProxyHttpPort+" -> P2P Tunnel -> %s:{80,443}", h.Addrs())
	// log.Printf("✅ P2P HTTP 代理启动: 监听 :%s", AgentProxyHttpPort)

	// 创建一个自定义的 HTTP Transport
	tr := &http.Transport{
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			// lzm modify 2025-12-16 16:57:31
			// // 1. 解析目标端口 (addr 格式通常为 "host:port")
			// _, port, err := net.SplitHostPort(addr)
			// if err != nil {
			// 	port = "80" // 默认回退
			// }
			// if port == "" {
			// 	port = "80"
			// }
			//
			// // 2. 建立 P2P 流
			// s, err := h.NewStream(ctx, serverPID, TunnelProtocol)
			// if err != nil {
			// 	return nil, err
			// }
			//
			// // 3. 发送目标端口给 Proxy (以换行符结束)
			// s.SetWriteDeadline(time.Now().Add(5 * time.Second))
			// _, err = s.Write([]byte(port + "\n"))
			// s.SetWriteDeadline(time.Time{}) // 重置超时
			// if err != nil {
			// 	s.Close()
			// 	return nil, fmt.Errorf("发送端口信息失败: %v", err)
			// }
			//
			// // 返回包装后的对象，使其满足 net.Conn 接口
			// return &StreamConn{Stream: s}, nil

			// 1. 从 Context 获取目标信息
			targetPort, _ := ctx.Value("TargetPort").(string)
			targetDomain, _ := ctx.Value("TargetDomain").(string)
			enableZip, _ := ctx.Value("EnableZip").(string)

			// 默认端口处理
			if targetPort == "" {
				targetPort = "80"
			}

			// 2. 构造握手协议 (适配 p2p_proxy 的新逻辑)
			// 格式: "domain:port\n" (例如: pay.4080517.com:443\n)
			// 如果没有域名，则只发送端口 (兼容旧版或本地转发)
			handshakeMsg := targetPort
			if targetDomain != "" {
				handshakeMsg = fmt.Sprintf("%s:%s|%s", targetDomain, targetPort, enableZip)
			}
			handshakeMsg += "\n"

			// 3. 建立 P2P 流连接到 Proxy
			s, err := h.NewStream(context.Background(), serverPID, TunnelProtocol)
			if err != nil {
				return nil, fmt.Errorf("P2P流创建失败: %w", err)
			}

			// 4. 发送握手信息给 Proxy
			_, err = s.Write([]byte(handshakeMsg))
			if err != nil {
				s.Close()
				return nil, fmt.Errorf("发送握手失败: %w", err)
			}
			// 返回包装后的流 (适配 net.Conn)
			// StreamConn 是你代码中已有的结构体，用于适配 net.Conn
			// return &StreamConn{s}, nil
			rawConn := &StreamConn{s}
			if enableZip == "1" {
				// 如果开启压缩，返回包装了 Snappy 的连接
				return NewSnappyConn(rawConn), nil
			}
			return rawConn, nil
		},
		DisableKeepAlives: true,
		MaxIdleConns:      100,
		IdleConnTimeout:   90 * time.Second,
		// 关键：允许自签名证书（因为我们通过隧道访问，可能涉及复杂的证书环境）
		TLSClientConfig:       &tls.Config{InsecureSkipVerify: true}, // 允许自签名证书 (HTTPS 转发关键)
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	// 创建反向代理
	rp := &httputil.ReverseProxy{
		Director: func(req *http.Request) {
			// lzm modify 2025-12-16 16:57:31
			// // 1. 确定协议 (HTTP vs HTTPS)
			// scheme := "http"
			// if req.TLS != nil {
			// 	scheme = "https"
			// }
			//
			// // 2. 确定目标端口
			// // 优先使用 Context 中的端口，否则根据协议选择默认端口
			// port, ok := req.Context().Value("TargetPort").(string)
			// if !ok || port == "" {
			// 	if scheme == "https" {
			// 		port = "443"
			// 	} else {
			// 		port = "80"
			// 	}
			// }
			//
			// req.URL.Scheme = scheme
			// req.URL.Host = fmt.Sprintf("%s:%s", targetDomain, port)
			// req.Host = targetDomain // 关键：设置 Host 头为目标域名
			// req.RequestURI = ""     // 必须清空
			//
			// 从 Context 获取 Handler 解析好的参数
			ctx := req.Context()
			targetScheme, _ := ctx.Value("TargetScheme").(string)
			targetDomain, _ := ctx.Value("TargetDomain").(string)
			targetPort, _ := ctx.Value("TargetPort").(string)

			// 设置目标 Host (影响 HTTP Host Header)
			if targetDomain != "" {
				req.Host = targetDomain
				// req.URL.Host = net.JoinHostPort(req.Host, targetPort)
			} else {
				req.Host = "127.0.0.1"
				// req.URL.Host = net.JoinHostPort(req.Host, targetPort)
			}

			// 设置目标端口
			if targetPort != "" {
				req.URL.Host = net.JoinHostPort(req.Host, targetPort)
			} else {
				// 如果没有指定端口，使用默认端口
				if req.URL.Scheme == "https" {
					req.URL.Host = net.JoinHostPort(req.Host, "443")
				} else {
					req.URL.Host = net.JoinHostPort(req.Host, "80")
				}
			}

			// 设置目标协议
			if targetScheme != "" {
				req.URL.Scheme = targetScheme
			} else {
				// 智能切换 HTTP/HTTPS
				// 如果端口是 443，强制使用 HTTPS 协议与后端交互
				if targetPort == "443" {
					req.URL.Scheme = "https"
				} else {
					req.URL.Scheme = "http"
				}
			}

			req.RequestURI = "" // 必须清空

		},
		Transport: tr,
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			// if v := r.Context().Value("P2PError"); v != nil {
			// 	if ec, ok := v.(*P2PErrorContainer); ok {
			// 		ec.Err = err
			// 	}
			// }

			// 错误处理逻辑...
			log.Printf("代理请求错误: %v", err)
			// 将错误传递给 Context 以便外层感知 (可选)
			if errContainer, ok := r.Context().Value("P2PError").(*P2PErrorContainer); ok {
				errContainer.Err = err
			}
			w.WriteHeader(http.StatusBadGateway)
		},
	}

	// 定义通用处理器
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// === 0. 新增：本地健康检查拦截 ===
		// 遇到 /_health 直接返回 200 OK，不走代理转发
		if r.URL.Path == "/_health" {
			// w.WriteHeader(http.StatusOK)
			// w.Write([]byte("OK"))
			// return

			// A. 检查与 p2p_proxy 的连接状态
			isConnected := h.Network().Connectedness(serverPID) == network.Connected
			// 强制在线，否则无法进入：[降级] Proxy 未连接，转为直连尝试
			//   因为：python和delphi的健康检查如果返回503会被判定为服务不可用，从而停止使用当前代理功能
			isConnected = true

			// B. 计算运行时间
			// uptime := time.Since(startTime)

			// lzm modify 2025-12-20 18:29:33
			// C. 判定逻辑
			// 情况1: 已连接 -> 返回 200 (正常)
			// 情况2: 未连接但处于启动宽限期(60秒内) -> 返回 200 (暂时视为正常，防止被监控误杀)
			// 情况3: 未连接且超过宽限期 -> 返回 503 (异常，Delphi 将检测到 False)
			//
			// 感觉不需要宽限期
			// if isConnected || uptime < 60*time.Second {
			if isConnected {

				w.WriteHeader(http.StatusOK)
				w.Write([]byte("OK"))
			} else {
				// 网络不通或代理断开，且重试超时
				w.WriteHeader(http.StatusServiceUnavailable)
				w.Write([]byte("Offline"))
			}

			return
		}
		// ==============================

		// // ✅ 新增：熔断保护
		// // 如果 Proxy 不在线，直接拒绝所有业务请求，不再尝试建立 P2P 流
		// if !isProxyOnline.Load() {
		// 	// 记录日志可选，避免刷屏
		// 	// log.Printf("⚠️ [熔断] 代理未连接，拒绝请求: %s", r.URL.Path)
		// 	http.Error(w, "P2P Proxy Unavailable - Connection Lost", http.StatusServiceUnavailable)
		// 	return
		// }

		// === 1. 读取并缓存 Request Body ===
		bodyBytes, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
			return
		}
		r.Body.Close()

		// lzm modify 2025-12-16 16:57:31
		// // === 2. 判断目标端口 (仅处理 URL 参数，默认值留给 Director) ===
		// targetPort := ""
		// if qPort := r.URL.Query().Get("_port"); qPort != "" {
		// 	targetPort = qPort
		// }
		// === 2. 解析并清理 URL 参数 ===
		query := r.URL.Query()

		// === 提取域名 (支持 _doman 和 _domain) ===
		targetDomain := ""
		if qDomain := query.Get("_doman"); qDomain != "" {
			targetDomain = qDomain
			query.Del("_doman")
		} else if qDomain := query.Get("_domain"); qDomain != "" {
			targetDomain = qDomain
			query.Del("_domain")
		}

		// 设置默认域名
		// 解决直接访问 127.0.0.1 报 404 的问题
		if targetDomain == "" {
			targetDomain = AdverserDomain // "shop.4080517.com"
		}
		// ========================

		// === 提取端口 ===
		targetPort := ""
		if qPort := query.Get("_port"); qPort != "" {
			targetPort = qPort
			query.Del("_port")
		}

		// 智能默认端口
		// 如果 URL 中没有指定 _port，则根据当前请求是否为 HTTPS 来决定默认端口
		if targetPort == "" {
			if r.TLS != nil {
				targetPort = "443" // 访问的是 https://127.0.0.1:9090 -> 默认转发到 443
			} else {
				targetPort = "80" // 访问的是 http://127.0.0.1:9090  -> 默认转发到 80
			}
		}
		// ============================

		// === 判断http还是https ===
		targetScheme := "http"

		// 提取 targetScheme
		if qScheme := query.Get("_scheme"); qScheme != "" {
			targetScheme = qScheme
			query.Del("_scheme")

		} else {

			if targetPort == "443" {
				targetScheme = "https"
				// log.Printf("targetPort == 443 -> https")
			}

			// 1. 检查当前连接是否为 TLS (HTTPS)
			if r.TLS != nil {
				targetScheme = "https"
				// log.Printf("r.TLS != nil -> https")
			}

			// 2. (可选) 如果 agent 运行在 Nginx/负载均衡后面，还需要检查 X-Forwarded-Proto
			if proto := r.Header.Get("X-Forwarded-Proto"); proto != "" {
				targetScheme = proto
				// log.Printf("X-Forwarded-Proto 存在 -> %s", proto)
			}
		}
		// ========================

		// === 提取压缩标记 ===
		enableZipCompression := "0"
		if qZip := query.Get("_zip"); qZip != "" {
			enableZipCompression = qZip
			query.Del("_zip")
		}
		if enableZipCompression == "" {
			enableZipCompression = "0"
		}
		// ============================

		targetHost := net.JoinHostPort(targetDomain, targetPort)
		r.URL.Scheme = targetScheme
		r.URL.Host = targetHost
		r.Host = targetDomain
		// 必须清空：避免把服务端请求语义带到客户端请求中
		r.RequestURI = ""

		// 检查是否连接到了 Proxy
		if h == nil || h.Network().Connectedness(serverPID) != network.Connected {
			// ⚠️ 关键点：不要返回错误，而是直接去尝试直连
			// log.Printf("⚠️ [降级] Proxy 未连接，转为直连尝试: %s:%s", targetDomain, targetPort)
			tryDirectAccess(targetScheme, targetDomain, targetPort, w, r, bodyBytes, "⚠️ [降级] Proxy 未连接")
			return
		}

		// log.Printf("✅ P2P Socket 代理启动: "+AgentProxyHttpPort+" -> P2P Tunnel -> %s:%s%s", targetDomain, targetPort, r.URL.Path)
		// log.Printf("✅ P2P Socket 代理启动: "+AgentProxyHttpPort+" -> P2P Tunnel -> :%s%s", targetPort, r.URL.Path)
		// log.Printf("P2P Tunnel -> %s:%s%s", targetDomain, targetPort, r.URL.Path)
		if r.URL.Path == "/index.php" {
			log.Printf("代理启动: "+AgentProxyHttpPort+" -> "+"P2P Tunnel -> %s://%s%s?%s", targetScheme, targetHost, r.URL.Path, query.Encode())
		} else {
			log.Printf("代理启动: "+AgentProxyHttpPort+" -> "+"P2P Tunnel -> %s://%s%s", targetScheme, targetHost, r.URL.Path)
		}

		// 重建 URL Query (移除已提取的参数，避免转发给后端)
		r.URL.RawQuery = query.Encode()

		// lzm modify 2025-12-16 16:57:31
		// // 3. 准备 Context 和 Body
		// errContainer := &P2PErrorContainer{}
		// ctx := context.WithValue(r.Context(), "P2PError", errContainer)
		// ctx = context.WithValue(ctx, "TargetPort", targetPort)
		//
		// rWithCtx := r.WithContext(ctx)
		// rWithCtx.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		//
		// // 4. 尝试 P2P 代理
		// rp.ServeHTTP(w, rWithCtx)
		//
		// // 5. 检查是否发生错误
		// if errContainer.Err != nil {
		// 	log.Printf("P2P Tunnel 访问失败: %v，正在回退到直接访问...", errContainer.Err)
		// 	// 6. 失败回退：直接访问
		// 	tryDirectAccess(targetDomain, targetPort, w, rWithCtx, bodyBytes)
		// }
		//
		// === 3. 准备 Context ===
		errContainer := &P2PErrorContainer{}
		ctx := context.WithValue(r.Context(), "P2PError", errContainer)
		ctx = context.WithValue(ctx, "TargetScheme", targetScheme)
		ctx = context.WithValue(ctx, "TargetPort", targetPort)
		ctx = context.WithValue(ctx, "TargetDomain", targetDomain)
		ctx = context.WithValue(ctx, "EnableZip", enableZipCompression)

		// 重建 Request (带 Body 和 Context)
		rWithCtx := r.WithContext(ctx)
		rWithCtx.Body = io.NopCloser(bytes.NewReader(bodyBytes))

		// === 4. 执行代理 ===
		// 如果是 HTTPS (443)，Transport 会自动进行 TLS 握手
		rp.ServeHTTP(w, rWithCtx)

		// === 5. 错误处理与回退 (可选) ===
		if errContainer.Err != nil {
			// log.Printf("⚠️ P2P 隧道失败，尝试直接访问: %v", errContainer.Err)
			// 如果 P2P 失败，尝试本地直接访问 (Direct Access)
			// 注意：如果目标是内网域名，本地直接访问可能也会失败
			tryDirectAccess(targetScheme, targetDomain, targetPort, w, r, bodyBytes, "⚠️ P2P 隧道失败")
		} else {
			// log.Printf("✅ P2P Tunnel 访问成功: %s", r.URL.Path)

			// if r.URL.Path == "/index.php" {
			// 	log.Printf("✅ P2P Tunnel 访问成功 %s://%s?%s", targetScheme, targetHost, r.URL.Path, query.Encode())
			// } else {
			// 	log.Printf("✅ P2P Tunnel 访问成功 %s://%s%s", targetScheme, targetHost, r.URL.Path)
			// }
		}
	})

	// === 启动端口复用监听 (HTTP & HTTPS on same port) ===
	l, err := net.Listen("tcp", ":"+AgentProxyHttpPort)
	if err != nil {
		log.Printf("❌ 本地 HTTP 代理启动失败: %v", err)
		return
	}

	log.Printf("🌐 本地 HTTP 代理启动，监听端口: %s", AgentProxyHttpPort)

	httpCh := make(chan net.Conn)
	httpsCh := make(chan net.Conn)

	// 分发器：读取第一个字节判断协议
	go func() {
		for {
			// lzm modify 2025-12-16 16:57:31
			c, err := l.Accept()
			if err != nil {
				continue
			}
			go func(conn net.Conn) {
				buf := make([]byte, 1)
				n, err := conn.Read(buf)
				if err != nil {
					conn.Close()
					return
				}
				// 包装连接，将读取的字节放回
				pc := &peekConn{Conn: conn, peeked: buf[:n]}

				// TLS 握手包通常以 0x16 (22) 开头
				if n > 0 && buf[0] == 0x16 {
					httpsCh <- pc
				} else {
					httpCh <- pc
				}
			}(c)
			// c, err := l.Accept()
			// if err != nil {
			// 	log.Printf("Accept error: %v", err)
			// 	continue
			// }
			// // 偷看第一个字节
			// peekC := &peekConn{Conn: c, peeked: make([]byte, 1)}
			// n, err := c.Read(peekC.peeked)
			// if err != nil || n == 0 {
			// 	c.Close()
			// 	continue
			// }
			//
			// // TLS 握手通常以 0x16 (22) 开头
			// if peekC.peeked[0] == 0x16 {
			// 	httpsCh <- peekC
			// } else {
			// 	httpCh <- peekC
			// }
		}
	}()

	// 启动 HTTP Server
	go func() {
		srv := &http.Server{Handler: handler}
		srv.Serve(&switchListener{Listener: l, ch: httpCh})
	}()

	// 启动 HTTPS Server (使用自签名证书)
	go func() {
		cert, err := generateSelfSignedCert()
		if err != nil {
			log.Printf("❌ 证书生成失败: %v", err)
			return
		}
		// lzm modify 2025-12-16 16:57:31
		srv := &http.Server{
			Handler:   handler,
			TLSConfig: &tls.Config{Certificates: []tls.Certificate{cert}},
		}
		// srv.Serve(&switchListener{Listener: l, ch: httpsCh})
		// ServeTLS 的 certFile/keyFile 为空，因为我们已经设置了 TLSConfig
		srv.ServeTLS(&switchListener{Listener: l, ch: httpsCh}, "", "")
	}()
}

func tryP2PTunnel(rp *httputil.ReverseProxy, w http.ResponseWriter, r *http.Request) error {
	rec := httptest.NewRecorder()
	rp.ServeHTTP(rec, r)

	// 检查响应状态码
	if rec.Code >= 200 && rec.Code < 300 {
		// 将响应写回客户端
		for k, v := range rec.Header() {
			w.Header()[k] = v
		}
		w.WriteHeader(rec.Code)
		_, err := w.Write(rec.Body.Bytes())
		return err
	}
	return fmt.Errorf("P2P Tunnel 返回状态码: %d", rec.Code)
}

//	func tryDirectAccess(domain, port string, w http.ResponseWriter, r *http.Request) {
//		client := &http.Client{}
//		url := fmt.Sprintf("http://%s:%s%s", domain, port, r.URL.Path)
//		if r.URL.RawQuery != "" {
//			url += "?" + r.URL.RawQuery
//		}
//
//		req, err := http.NewRequest(r.Method, url, r.Body)
//		if err != nil {
//			http.Error(w, "创建直接访问请求失败", http.StatusInternalServerError)
//			return
//		}
//
//		// 复制请求头
//		for k, v := range r.Header {
//			req.Header[k] = v
//		}
//
//		resp, err := client.Do(req)
//		if err != nil {
//			http.Error(w, "直接访问目标服务器失败", http.StatusBadGateway)
//			return
//		}
//		defer resp.Body.Close()
//
//		// 将响应写回客户端
//		for k, v := range resp.Header {
//			w.Header()[k] = v
//		}
//		w.WriteHeader(resp.StatusCode)
//		io.Copy(w, resp.Body)
//	}
func tryDirectAccess(scheme, domain, port string, w http.ResponseWriter, r *http.Request, bodyBytes []byte, logPrefix string) {
	// 1. 清理参数
	query := r.URL.Query()
	query.Del("_port")

	// 简单回退逻辑：如果没传端口，默认用 80 (HTTP)
	// 注意：这里仅实现了 HTTP 回退，如果需要 HTTPS 回退需要更复杂的逻辑
	if port == "" {
		port = "80"
	}

	// === 判断http还是https ===
	// 1. 检查当前连接是否为 TLS (HTTPS)
	if r.TLS != nil {
		scheme = "https"
	}

	// 2. (可选) 如果 agent 运行在 Nginx/负载均衡后面，还需要检查 X-Forwarded-Proto
	if proto := r.Header.Get("X-Forwarded-Proto"); proto != "" {
		scheme = proto
	}

	// 将协议应用到 URL 中 (如果需要转发)
	if r.URL.Scheme == "" {
		r.URL.Scheme = scheme
	}
	// ========================

	targetHost := net.JoinHostPort(domain, port)
	urlStr := fmt.Sprintf("%s://%s%s", scheme, targetHost, r.URL.Path)
	if len(query) > 0 {
		urlStr += "?" + query.Encode()
	}

	log.Printf(logPrefix+"，尝试直接访问 -> %s%s", targetHost, r.URL.Path)

	// 2. 创建新请求
	// 关键：直接使用 bytes.NewReader，http.NewRequest 会自动识别并设置 GetBody
	// 这样即使发生重定向或重试，也不会报 "invalid Read on closed Body"
	req, err := http.NewRequest(r.Method, urlStr, bytes.NewReader(bodyBytes))
	if err != nil {
		log.Printf("❌ 创建直接访问请求失败: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// 3. 复制 Header
	for k, v := range r.Header {
		req.Header[k] = v
	}
	req.Host = domain

	// 4. 发起请求
	client := &http.Client{
		Timeout: 30 * time.Second,
		// 允许自动跟随重定向，因为我们现在正确设置了 GetBody
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("❌ 直接访问目标服务器失败 (%s): %v", urlStr, err)
		http.Error(w, "Bad Gateway", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// 5. 返回响应
	for k, v := range resp.Header {
		for _, vv := range v {
			w.Header().Add(k, vv)
		}
	}
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

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
//			// 			// 	1. h.Connect 的工作机制：当你调用 h.Connect 并成功建立连接后，libp2p 的网络层和连接管理器（Connection Manager）会自动将这个成功的地址记录到 Peerstore 中。这意味着，这个刚刚被验证为有效的地址已经被 libp2p “记住”了。
//			// 			// 	2. UpdateAddrs 的作用：UpdateAddrs 的主要作用是手动提升地址的“可信度”，通过修改它的 TTL（Time-To-Live，存活时间）。
//			// 			// 		peerstore.TempAddrTTL：一个临时的、很快会过期的地址。
//			// 			// 		peerstore.PermanentAddrTTL：一个永久的、不会过期的地址。
//			// 			// 		调用 UpdateAddrs 将地址的 TTL 从临时提升到永久，相当于告诉 libp2p：“这个地址非常可靠，请优先使用并长期保留它”。
//			// 			// 结论
//			// 			// 	不加 UpdateAddrs：代码依然可以正常工作。libp2p 在连接成功后已经知道了这个有效地址，并会在其默认的 TTL 内保留它。
//			// 			// 	加上 UpdateAddrs：这是一个优化措施。它可以确保这个已知的、稳定的 p2p_proxy 地址不会因为 TTL 过期而从 Peerstore 中被意外清除，从而让未来的重连更快速、更稳定。
//			// 			h.Peerstore().UpdateAddrs(targetPeerID, peerstore.TempAddrTTL, peerstore.PermanentAddrTTL)
//			// 		}
//			// 	} else {
//			// 		// 如果已连接，也重置计数器
//			// 		failCount = 0
//			//
//			// 		// 已连接
//			// 		// isProxyOnline.Store(true)
//			// 	}
//			// }
//			tryConnect := func() {
//				// 如果已经连接，跳过
//				if h.Network().Connectedness(targetPeerID) == network.Connected {
//					// 如果已连接，也重置计数器
//					failCount = 0
//
//					return
//				}
//
//				// // 1. 检查 Peerstore 中是否有 p2p_proxy 的地址
//				// addrs := h.Peerstore().Addrs(targetPeerID)
//				// // 2. 如果没有地址（MDNS 还没发现），手动注入回退地址
//				// if len(addrs) == 0 {
//				// 	log.Println("⚠️ 暂无 p2p_proxy 地址信息，注入默认回退地址 (" + ADVERSER + ")...")
//				// 	h.Peerstore().AddAddr(targetPeerID, fallbackAddr, peerstore.TempAddrTTL)
//				// }
//
//				// log.Println("🔄 [连接守护] 检测到未连接，尝试重连...")
//
//				// lzm modify 2026-01-05 02:01:32
//				// // 1. 尝试通过 PeerStore 中的地址连接
//				// if err := h.Connect(ctx, peer.AddrInfo{ID: targetPeerID}); err != nil {
//				// 	// log.Printf("⚠️ 重连失败: %v", err)
//				//
//				// 	// 2. 如果直连失败，尝试连接回退地址 (Bootstrap Node)
//				// 	if fallbackAddr != nil {
//				// 		failCount++
//				// 		// 静默策略：仅在第1次失败，或每11次(约1分钟)打印一次错误日志
//				// 		if failCount == 1 || failCount%11 == 0 {
//				// 			log.Printf("🔄 [连接守护] 检测到未连接，尝试重连... (已尝试 %d 次) %s: %v", failCount, fallbackAddr, err)
//				// 			// log.Printf("🔄 尝试连接回退地址: %s", fallbackAddr)
//				// 		}
//				// 		h.Connect(ctx, peer.AddrInfo{ID: targetPeerID, Addrs: []multiaddr.Multiaddr{fallbackAddr}})
//				// 	}
//				// } else {
//				// 	// 连接成功，重置计数器 (ConnectedF 回调会处理后续逻辑)
//				// 	failCount = 0
//				//
//				// 	// 主动连接成功后，ConnectedF 会被触发，那里会处理注册
//				// 	log.Println("✅ [连接守护] 重连成功！")
//				// }
//				//
//				// 原先可能直接 h.Connect(ctx, peer.AddrInfo{ID: targetPeerID, Addrs: addrs})
//				// 改为使用带地址过滤与回退的 dialProxy
//				if err := dialProxy(ctx, h, targetPeerID, fallbackAddr); err != nil {
//					log.Printf("重连失败: %v", err)
//					failCount++
//					return
//				}
//				failCount = 0
//
//			}
//
//			// === 新增：立即执行一次连接尝试 ===
//			log.Println("🚀 [连接守护] 正在发起首次连接...")
//			tryConnect()
//			// =================================
//
//			for {
//				select {
//				case <-ctx.Done():
//					return
//				case <-ticker.C:
//					// 定时检查并尝试重连
//					// tryConnect()
//
//					// 1. 获取物理连接状态 (Libp2p 底层状态)
//					netState := h.Network().Connectedness(targetPeerID)
//
//					// 2. 获取业务注册状态 (应用层状态)
//					businessReady := isRegistered.Load()
//
//					// 3. 状态诊断与处理
//					if netState == network.Connected {
//						if businessReady {
//							// [正常状态]：物理连接正常 且 业务已注册 -> 维持现状
//							continue
//						}
//
//						// [异常状态 - 假在线]：物理连接显示 Connected，但业务未注册
//						// 这种情况通常发生在：
//						// a. TCP 连接处于半开状态 (Half-Open)
//						// b. 注册流已断开，但 Libp2p 还没感知到 Peer 下线
//						// c. 刚刚连上但注册超时失败
//						log.Printf("⚠️ [连接守护] 检测到假在线 (Connectedness=Connected, Registered=false)")
//						log.Printf("🧹 [连接守护] 执行强制清理: ClosePeer(%s)", targetPeerID)
//
//						// 4. 关键修复：强制关闭 Peer
//						// 这一步至关重要！它会强制 Libp2p 遗忘该节点的连接状态，并关闭底层 Socket。
//						// 如果不调用此方法，Libp2p 会一直认为连接存在，从而拒绝发起新的 Dial。
//						_ = h.Network().ClosePeer(targetPeerID)
//
//						// 强制关闭后，状态被重置，代码将继续向下执行重连逻辑
//					}
//
//					// 5. 执行重连 (物理未连接 或 刚刚被强制清理)
//					log.Printf("🔄 [连接守护] 发起连接: %s", targetPeerID)
//
//					// 调用拨号函数
//					// dialProxy 内部应包含 h.Connect 和 身份注册逻辑
//					if err := dialProxy(ctx, h, targetPeerID, fallbackAddr); err != nil {
//						log.Printf("❌ [连接守护] 连接失败: %v", err)
//					} else {
//						log.Printf("✅ [连接守护] 连接过程完成")
//					}
//				}
//
//			}
//		}()
//	}
//
// // dialProxy 建立到指定对等节点的代理连接
// // 该函数会过滤掉不可用的地址（如回环地址），并使用回退地址作为备用
//
//	func dialProxy(ctx context.Context, h host.Host, pid peer.ID, fallbackAddr ma.Multiaddr) error {
//		// 过滤出可用地址（排除 127.0.0.1、私网段）
//		var addrs []ma.Multiaddr
//		for _, a := range h.Peerstore().Addrs(pid) {
//			if isRelayConn(a) { // 若需要可保留中继
//				addrs = append(addrs, a)
//				continue
//			}
//			// lzm modify 2026-01-05 02:12:02
//			// 提取 IP 并进行准确检查 (替代原来的字符串过滤)
//			// if strings.Contains(a.String(), "/127.0.0.1/") { // 简化过滤，可改用 ParseIP 检查
//			// 	continue
//			// }
//			ip, err := manet.ToIP(a)
//			if err == nil {
//				// 过滤回环地址 (127.0.0.1 和 ::1)
//				if ip.IsLoopback() {
//					continue
//				}
//				// 可选：如果你想过滤局域网 IP (192.168..., 10..., 172.16...)
//				// if ip.IsPrivate() {
//				//     continue
//				// }
//			}
//
//			addrs = append(addrs, a)
//		}
//		// 若无可用地址，使用回退地址
//		if len(addrs) == 0 && fallbackAddr != nil {
//			addrs = []ma.Multiaddr{fallbackAddr}
//			h.Peerstore().AddAddr(pid, fallbackAddr, peerstore.TempAddrTTL)
//		}
//		return h.Connect(ctx, peer.AddrInfo{ID: pid, Addrs: addrs})
//	}
//
// // 向 p2p_proxy 发送身份认证信息
//
//	func registerToServerB(ctx context.Context, h host.Host, targetPID peer.ID) {
//		// 打开一个新的流用于认证
//		s, err := h.NewStream(ctx, targetPID, P2PProtocol)
//		if err != nil {
//			log.Printf("❌ [连接] 打开注册流失败: %v", err)
//			return
//		}
//
//		// 构造认证数据
//		authData := map[string]string{
//			"user_id":  getUserIDFromRegistry(),
//			"shopid":   getShopIDFromIni(),
//			"shopname": getShopNameFromIni(),
//		}
//		jsonData, _ := json.Marshal(authData)
//
//		// 发送数据 (p2p_proxy 使用 ReadBytes('\n') 读取，所以必须加换行符)
//		_, err = s.Write(append(jsonData, '\n'))
//		if err != nil {
//			log.Printf("❌ [连接] 发送认证信息失败: %v", err)
//			s.Close()
//			return
//		}
//
//		log.Printf("✅ 身份认证信息已发送: %s", string(jsonData))
//
//		// 启动一个读取循环，保持流活跃，并处理可能的响应或心跳
//		// 如果 p2p_proxy 发送心跳，这里会接收到
//		go func() {
//			defer s.Close()
//			buf := make([]byte, 1024)
//			for {
//				_, err := s.Read(buf)
//				if err != nil {
//					log.Printf("ℹ️ 注册流结束: %v", err)
//					return
//				}
//				// 忽略收到的数据 (心跳等)，保持流畅通
//			}
//		}()
//	}
//
// startReconnectionMonitor 连接守护主循环 (替代了旧版复杂的 Notify 逻辑)，
// 逻辑：死循环调用 dialProxy。只要 dialProxy 返回，就说明连接断了，立即清理并重连。
// 所以调用此函数前加 "go" 关键字这样它会在后台独立运行，不会卡住主线程
func startReconnectionMonitor(ctx context.Context, h host.Host, targetPeerID peer.ID) {
	log.Printf("🚀 [连接p2p_proxy守护] 启动，目标 p2p_proxy: %s", targetPeerID)

	// 启动时先清理一次，防止残留状态
	h.Network().ClosePeer(targetPeerID)

	// 死循环：只要 dialProxy 返回（意味着断开了），就立即重连
	for {
		// 如果程序退出，则停止
		if ctx.Err() != nil {
			return
		}

		// === 核心变化 ===
		// 调用阻塞式连接函数。
		// 这个函数会一直运行（阻塞），直到连接断开或出错才会返回。
		dialProxy(ctx, h, targetPeerID)

		// 如果代码执行到这里，说明 dialProxy 返回了（连接断了）
		log.Printf("⚠️ [连接p2p_proxy守护] 检测到连接断开，5秒后重连...")

		// 标记为离线
		isRegistered.Store(false)

		// 强制清理底层连接，确保下次重连是干净的
		h.Network().ClosePeer(targetPeerID)

		// 等待 5 秒再重试
		select {
		case <-ctx.Done():
			return
		case <-time.After(5 * time.Second):
			// 继续下一次循环 -> 重连
		}
	}
}

// dialProxy (替代原有的 tryConnect)
// 负责：建立连接 -> 身份注册 -> 保持心跳 (阻塞) (替代了 registerToServerB)
func dialProxy(ctx context.Context, h host.Host, pid peer.ID) {
	// 1. 确保 Peerstore 中有地址 (注入回退地址，防止 DHT 没找到时无法连接)
	if fallbackAddr, err := multiaddr.NewMultiaddr(ADVERSER); err == nil {
		h.Peerstore().AddAddr(pid, fallbackAddr, peerstore.TempAddrTTL)
	}

	log.Printf("🔄 [连接p2p_proxy] 正在连接代理服务器...")

	// 2. 发起连接 (LibP2P 底层连接) (h.Connect 会阻塞直到连接建立或失败)
	// 这里不需要检查 network.Connected，因为如果已连接，Connect 会直接返回 nil
	if err := h.Connect(ctx, peer.AddrInfo{ID: pid}); err != nil {
		log.Printf("❌ [连接p2p_proxy] 物理连接失败: %v", err)
		return // 连接失败，返回让外层等待 5 秒重试
	}

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
	s, err := h.NewStream(ctx, targetPID, P2PProtocol)
	if err != nil {
		log.Printf("❌ [注册] 打开流失败: %v", err)
		return
	}
	defer s.Close()

	// 构造认证信息
	authData := map[string]string{
		"user_id":  getUserIDFromRegistry(),
		"shopid":   getShopIDFromIni(),
		"shopname": getShopNameFromIni(),
	}
	jsonData, _ := json.Marshal(authData)

	// 发送认证信息 (带超时防止卡死)
	s.SetWriteDeadline(time.Now().Add(5 * time.Second))
	_, err = s.Write(append(jsonData, '\n'))
	s.SetWriteDeadline(time.Time{}) // 清除超时

	if err != nil {
		log.Printf("❌ [注册] 发送认证信息失败: %v", err)
		return
	}

	log.Printf("✅ [注册] 注册成功，通道已建立 (保持在线中...)")
	// log.Printf("✅ [注册] 身份认证成功，连接守护中...")
	isRegistered.Store(true)        // 标记业务在线
	defer isRegistered.Store(false) // 函数退出(断开)时标记为离线

	// === 阻塞读取循环 (心跳保活) (替代了 network.Connected 检查) ===
	// 只要这个循环不退，就代表连接正常。一旦退出，外层就会重连。
	// 只要 Read 不报错，就说明连接正常。 一旦报错（EOF 或 Reset），说明连接断了，函数返回。
	buf := make([]byte, 1024)
	for {
		// 设置读取超时 (例如 15 秒)，p2p_proxy 每 5 秒发一次心跳
		// 如果 15 秒没收到数据，说明网络断了
		s.SetReadDeadline(time.Now().Add(15 * time.Second))

		_, err := s.Read(buf)
		if err != nil {
			log.Printf("⚠️ [注册] 连接断开 (读取超时或错误): %v", err)
			return // 返回 -> dialProxy 返回 -> startReconnectionMonitor 重连
		}
		// 收到数据(如心跳)，继续保持循环
	}
}

func SavePrivateKeyToFile(filename string, priv crypto.PrivKey) error {
	privBytes, err := crypto.MarshalPrivateKey(priv)
	if err != nil {
		return fmt.Errorf("密钥序列化失败: %v", err)
	}

	versionedKey := VersionedKey{
		Version: 1,
		KeyData: privBytes,
		Magic:   []byte(fmt.Sprintf("LIBP2PKEY-%d.0", 1)),
	}

	data, _ := json.Marshal(versionedKey)
	return os.WriteFile(filename, data, 0600)
}

func loadServerAKey() crypto.PrivKey {
	// privKey := loadServerAKeyFromFile()
	// pubKey := privKey.GetPublic()
	// testID, _ := peer.IDFromPublicKey(pubKey)
	// log.Printf("测试：文件的PeerID = %s", testID)

	return loadServerAKeyFromReg()
}

func loadServerAKeyFromReg() crypto.PrivKey {
	const regPath = `SOFTWARE\SuperTouch\info`
	const regKeyName = "p2p_agent_key"

	// 尝试以读写权限打开注册表项，优先使用 64 位视图
	k, err := registry.OpenKey(registry.LOCAL_MACHINE, regPath, registry.READ|registry.WRITE|registry.WOW64_32KEY)
	if err != nil {
		// 如果失败，尝试使用默认视图（可能是 32 位）
		k, err = registry.OpenKey(registry.LOCAL_MACHINE, regPath, registry.READ|registry.WRITE)
		if err != nil {
			log.Fatalf("❌ 致命错误：无法打开注册表项 '%s' (需要管理员权限): %v", regPath, err)
		}
	}
	// 确保即使在后续出错的情况下也能关闭句柄
	defer func() {
		k.Close()
	}()

	// 尝试读取密钥
	keyDataStr, _, err := k.GetStringValue(regKeyName)
	if err != nil && err != registry.ErrNotExist {
		log.Fatalf("❌ 致命错误：读取注册表值 '%s' 失败: %v", regKeyName, err)
	}

	// 如果密钥存在，则解析并返回
	if err == nil {
		var versionedKey VersionedKey
		if err := json.Unmarshal([]byte(keyDataStr), &versionedKey); err != nil {
			log.Fatalf("❌ 致命错误：注册表中的密钥格式错误: %v", err)
		}

		if versionedKey.Version != CurrentFormatVersion {
			log.Fatalf("❌ 致命错误：不支持的密钥版本: %d", versionedKey.Version)
		}

		priv, err := crypto.UnmarshalPrivateKey(versionedKey.KeyData)
		if err != nil {
			log.Fatalf("❌ 致命错误：注册表中的密钥解析失败: %v", err)
		}

		log.Printf("✅ 已从注册表加载本机身份密钥")
		return priv
	}

	// --- 如果密钥不存在，则生成并保存 ---
	log.Printf("ℹ️ 注册表中未找到密钥，正在为本机生成唯一身份密钥...")
	priv, _, err := crypto.GenerateKeyPair(crypto.ECDSA, 256)
	if err != nil {
		log.Fatalf("❌ 致命错误：生成新密钥失败: %v", err)
	}

	// 序列化密钥
	privBytes, err := crypto.MarshalPrivateKey(priv)
	if err != nil {
		log.Fatalf("❌ 致命错误：密钥序列化失败: %v", err)
	}

	versionedKey := VersionedKey{
		Version: CurrentFormatVersion,
		KeyData: privBytes,
		Magic:   []byte(fmt.Sprintf("LIBP2PKEY-%d.0", CurrentFormatVersion)),
	}

	jsonData, err := json.Marshal(versionedKey)
	if err != nil {
		log.Fatalf("❌ 致命错误：无法将新密钥转换为 JSON: %v", err)
	}

	// 将 JSON 字符串写入注册表
	err = k.SetStringValue(regKeyName, string(jsonData))
	if err != nil {
		log.Fatalf("❌ 致命错误：无法将新密钥写入注册表 (需要管理员权限): %v", err)
	}

	log.Printf("✅ 已成功生成新密钥并保存到注册表")
	return priv
}

func loadServerAKeyFromFile() crypto.PrivKey {
	userId := getUserIDFromRegistry()
	shopid := getShopIDFromIni()
	shoptag := fmt.Sprintf("%s_%s", userId, shopid)

	keyFileName := fmt.Sprintf(""+AppName+"_%s.key", shoptag)

	if _, err := os.Stat(keyFileName); os.IsNotExist(err) {
		log.Printf("密钥文件 %s 不存在，正在为本机生成唯一身份密钥...", keyFileName)
		priv, _, err := crypto.GenerateKeyPair(crypto.ECDSA, 256)
		if err != nil {
			log.Fatal(err)
		}
		err = SavePrivateKeyToFile(keyFileName, priv)
		if err != nil {
			log.Fatalf("致命错误：无法保存私钥文件: %v", err)
		}
	}

	data, err := os.ReadFile(keyFileName)
	if err != nil {
		log.Fatalf("致命错误：无法读取私钥文件: %v", err)
	}

	var versionedKey VersionedKey
	if err := json.Unmarshal(data, &versionedKey); err != nil {
		log.Fatalf("致命错误：私钥格式错误: %v", err)
	}

	if versionedKey.Version != 1 {
		log.Fatalf("致命错误：不支持的密钥版本: %d", versionedKey.Version)
	}

	priv, err := crypto.UnmarshalPrivateKey(versionedKey.KeyData)
	if err != nil {
		log.Fatalf("致命错误：私钥解析失败: %v", err)
	}

	log.Printf("已加载本机身份密钥: %s", keyFileName)
	return priv
}

func loadServerBKey() crypto.PrivKey {
	data, err := os.ReadFile(BkeyFileName)
	if err != nil {
		log.Fatalf("致命错误：无法读取私钥文件: %v", err)
	}

	var versionedKey VersionedKey
	if err := json.Unmarshal(data, &versionedKey); err != nil {
		if len(data) > 12 && string(data[:12]) == "LIBP2PKEY-1.0" {
			priv, err := crypto.UnmarshalPrivateKey(data[12:])
			if err != nil {
				log.Fatalf("致命错误：旧版私钥解析失败: %v", err)
			}
			return priv
		}
		log.Fatalf("致命错误：私钥格式错误: %v", err)
	}

	if versionedKey.Version != 1 {
		log.Fatalf("致命错误：不支持的密钥版本: %d", versionedKey.Version)
	}

	priv, err := crypto.UnmarshalPrivateKey(versionedKey.KeyData)
	if err != nil {
		log.Fatalf("致命错误：私钥解析失败: %v", err)
	}
	return priv
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
	s.Write([]byte("VERSION " + ProtocolVersion))
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
	action, _ := meta["action"].(string)
	// uid, _ := meta["user_id"].(string)
	// shopid, _ := meta["shopid"].(string)
	// log.Printf("收到请求: action=%s user_id=%s shopid=%s", action, uid, shopid)

	// 根据 action 执行不同逻辑
	if action == "querysql" {
		handleQuerySql(s, meta["sql"].(string))
	} else if action == "graphql" {
		// === 新增 GraphQL 支持 ===
		query, _ := meta["query"].(string)

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
	addr, _ := ma.NewMultiaddr(ADVERSER) // p2p_proxy 地址

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
	// 	log.Println("✅ 成功建立到底层 p2p_proxy 的连接")
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
			Addrs: []ma.Multiaddr{addr},
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

// min 返回两个 time.Duration 的较小值（Go 1.20 没有内置 min 泛型）
func min(a, b time.Duration) time.Duration {
	if a < b {
		return a
	}
	return b
}

// 获取 本店guid
func getUserMCCODEFromRegistry() string {
	k, err := registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\SuperTouch\YPPay`, registry.QUERY_VALUE|registry.WOW64_32KEY)
	if err != nil {
		k, err = registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\SuperTouch\YPPay`, registry.QUERY_VALUE)
		if err != nil {
			log.Fatal(err)
			return "OpenKey_打开注册表权限不足"
		}
	}
	defer k.Close()

	val, _, err := k.GetStringValue("mccode")
	if err != nil {
		return "读取本店guid值失败"
	}
	return val
}

// ... (getUserIDFromRegistry, getShopIDFromIni 保持不变)
func getUserIDFromRegistry() string {
	k, err := registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\SuperTouch\info`, registry.QUERY_VALUE|registry.WOW64_32KEY)
	if err != nil {
		k, err = registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\SuperTouch\info`, registry.QUERY_VALUE)
		if err != nil {
			log.Fatal(err)
			return "OpenKey_打开注册表权限不足"
		}
	}
	defer k.Close()

	val, _, err := k.GetStringValue("userid_user_id")
	if err != nil {
		return "读取user_id值失败"
	}

	// 如果 user_id 是空则取 本机guid
	if val == "" {
		val = getUserMCCODEFromRegistry()
	}

	return val
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

// 通用读取 INI 的函数：path 为文件路径，targetSection/targetKey 忽略大小写匹配。
// useACP 指示是否根据 Windows ACP 做编码转换（用于包含 GBK/Big5 的文件）。
// 修改说明：readIniValue 增加了 defaultVal 参数，并将 useACP 改为可选参数（默认 true）。
func readIniValue(path, targetSection, targetKey string, defaultVal string, useACP ...bool) string {
	file, err := os.Open(path)
	if err != nil {
		return defaultVal
	}
	defer file.Close()

	// 可选参数：默认 useACP = true
	useACPFlag := true
	if len(useACP) > 0 {
		useACPFlag = useACP[0]
	}

	var reader io.Reader = file

	if useACPFlag {
		// 获取系统 ACP
		getACP := func() uint32 {
			kernel32 := syscall.NewLazyDLL("kernel32.dll")
			procGetACP := kernel32.NewProc("GetACP")
			ret, _, _ := procGetACP.Call()
			return uint32(ret)
		}
		acp := getACP()
		switch acp {
		case 936:
			reader = transform.NewReader(file, simplifiedchinese.GB18030.NewDecoder())
		case 950:
			reader = transform.NewReader(file, traditionalchinese.Big5.NewDecoder())
		default:
			reader = file
		}
	}

	scanner := bufio.NewScanner(reader)
	inTarget := false
	targetSection = strings.ToLower(targetSection)
	targetKey = strings.ToLower(targetKey)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, ";") || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			section := strings.ToLower(strings.Trim(line, "[]"))
			inTarget = (section == targetSection)
			continue
		}
		if inTarget {
			if idx := strings.Index(line, "="); idx > 0 {
				key := strings.ToLower(strings.TrimSpace(line[:idx]))
				if key == targetKey {
					val := strings.TrimSpace(line[idx+1:])
					if val == "" {
						return defaultVal
					}
					return val
				}
			}
		}
	}
	return defaultVal
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

// 新增：从 postgresql.conf 读取端口
func getPostgresPortFromConf() string {
	// 路径: ..\pgsql\data\postgresql.conf
	confPath := filepath.Join("..", "pgsql", "data", "postgresql.conf")
	file, err := os.Open(confPath)
	if err != nil {
		return "5432" // 打开失败返回默认值
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// 忽略整行注释 (# 开头)
		if strings.HasPrefix(line, "#") {
			continue
		}

		// 处理行内注释 (去除 # 及之后的内容)
		if idx := strings.Index(line, "#"); idx >= 0 {
			line = strings.TrimSpace(line[:idx])
		}

		// 忽略空行
		if line == "" {
			continue
		}

		// 解析 Key = Value
		if idx := strings.Index(line, "="); idx > 0 {
			key := strings.TrimSpace(line[:idx])
			// PostgreSQL 参数名不区分大小写
			if strings.EqualFold(key, "port") {
				return strings.TrimSpace(line[idx+1:])
			}
		}
	}
	return "5432" // 未找到配置返回默认值
}

// 新增：从 UltraVNC.ini 读取端口
func getVNCPortFromIni() string {
	// 假设 UltraVNC 目录在当前运行目录下
	vncIniPath := filepath.Join("UltraVNC", "UltraVNC.ini")
	file, err := os.Open(vncIniPath)
	if err != nil {
		return "8900" // 文件打开失败，返回默认值
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	inAdminSection := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// 忽略空行和注释
		if line == "" || strings.HasPrefix(line, ";") || strings.HasPrefix(line, "#") {
			continue
		}

		// 识别 Section (忽略大小写)
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			section := strings.Trim(line, "[]")
			// 目标 Section: [admin]
			if strings.EqualFold(section, "admin") {
				inAdminSection = true
			} else {
				inAdminSection = false
			}
			continue
		}

		// 识别 Key (忽略大小写)
		if inAdminSection {
			if idx := strings.Index(line, "="); idx > 0 {
				key := strings.TrimSpace(line[:idx])
				// 目标 Key: portnumber
				if strings.EqualFold(key, "portnumber") {
					val := strings.TrimSpace(line[idx+1:])
					if val != "" {
						return val
					}
				}
			}
		}
	}
	return "8900" // 未找到配置，返回默认值
}
