package main

import (
	"sync"
	"sync/atomic"

	"github.com/graphql-go/graphql"
	"github.com/libp2p/go-libp2p/core/peer"
)

var (
	clientMeta     = make(map[peer.ID]ClientMeta)
	clientMetaMu   sync.RWMutex
	ADVERSER       = "" // p2p_proxy 地址
	AdverserIp     = ""
	AdverserDomain = ""
	p2pSchema      graphql.Schema

	// 定义一个全局变量用于存储命令行参数
	adverserIPFlag string

	// ✅ 全局变量：标记 p2p_proxy 是否在线
	// isProxyOnline atomic.Bool

	// 标记是否本机作为“服务器”（SupertouchPCDataIP 指向本机/回环则为 true）
	isLocalServer      bool
	SupertouchPCDataIP string
)

// 新增全局等待表（key = identity + "|" + reqID）
var (
	pendingMu   sync.Mutex
	pendingResp = make(map[string]chan string)
)

// 全局状态标记：用于让监控协程知道“业务层”是否真的通了
var isRegistered atomic.Bool
