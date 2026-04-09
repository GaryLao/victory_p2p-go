package main

/**
为什么新版的0.32.4有问题？
------
这是一个很好的问题。为什么代码完全一样，仅仅升级 libp2p 库版本（从 0.26.4 升到 0.32.x），P2P 打洞就失效了？

主要原因是 libp2p 在 v0.27+ 引入了重大架构变更，特别是针对 NAT 打洞和资源管理的策略：

资源管理器 (Resource Manager) 的默认限制变严：
旧版 (0.24-0.26)：默认策略比较宽松，允许大量的并发尝试。
新版 (0.27+)：为了防止 DDoS，默认启用了非常严格的 SystemLimit 和 TransientLimit。
后果：P2P 打洞需要同时向多个候选地址发包。新版可能因为“并发连接数过多”或“内存使用超标”而在后台默默掐断了打洞尝试，导致你看到 context deadline exceeded。即使我们代码里写了 InfiniteLimits，某些底层默认值（如 fd 限制）可能仍未生效。
AutoNAT 和 Reachability 逻辑变更：
旧版：一旦配置了 ForceReachabilityPrivate，它会非常积极地去寻找中继。
新版：引入了更复杂的“自信度”检测。如果新版 AutoNAT 认为我在公网（误判），或者还没完全确定状态，它可能会拒绝发起 P2P 打洞请求，而是傻傻地等待对方连我。
Hole Punching (DCUtR) 协议升级：
协议不兼容：libp2p 的打洞协议（DCUtR）在不同版本间可能存在不兼容。如果 Proxy 还是旧版（或行为不同），新版 Agent 发出的打洞同步指令可能无法被正确理解。
QUIC 优先：新版极度倾向于使用 QUIC/UDP 进行打洞。而你的环境（校园网/企业网）可能对 UDP 并不友好，或者防火墙策略只放行了 TCP。旧版对 TCP 打洞的支持可能更“顽固”一些，效果反而更好。
总结
简单来说，新版 libp2p 变得更“聪明”但也更“洁癖”了。它加了很多安全限制和智能判断，但在复杂的 NAT 环境下，这些聪明反倒成了累赘。而旧版 (0.26.4) 比较“莽”，只要你说打洞，它就拼命发包，反而更容易打通。

既然 0.26.4 稳定且好用，坚持使用它是最明智的选择。 除非未来必须要用到 QUIC 的某些新特性，否则没必要折腾升级。

==============================================================
确实，p2p_proxy 使用的是 libp2p 0.32.2。
------
这就解释了为什么打洞会遇到问题：

Proxy (Server): v0.32.2 (新版)
Agent (Client):
旧版 Agent (v0.26.4): ✅ 能打通。旧版客户端比较“积极”且限制少，即使 Server 是新版，也能兼容这一套流程。
新版 Agent (v0.32.2): ❌ 配上新版 Proxy 其实原本应该是最兼容的。但因为我之前提到的 AutoNAT/AutoRelay 配置、资源限制、以及 QUIC/UDP 协商 等问题，导致这俩“新版”凑在一起反而因为彼此都太“严谨”而无法建立直连（特别是当 AutoNAT 误判或状态不确定时）。
为什么旧版客户端能连新版 Proxy？
libp2p 的打洞协议（DCUtR）和 Circuit Relay v2 协议是有向后兼容性的。旧版 Agent 发起的请求，新版 Proxy 仍然认识。而且旧版 Agent 没有新版那么多繁琐的“前置检查”（比如必须先确定 Reachability 才能打洞），所以它反而更容易成功。

目前的最佳实践：

Proxy: 0.32.2 (保持现状，性能更好)
Agent: 0.26.4 (保持现状，打洞效果最好)
混合版本目前看是最稳定的组合。
*/

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"runtime"
	"time"

	"github.com/graphql-go/graphql"
	_ "github.com/lib/pq"
)

func init() {
	log.Printf("🚀 " + AppName + " 启动中...........................................................")

	// 预分配 4 个 reader/writer，避免启动/突发并发时大量 NewReader 分配
	initS2Pools(4)

	// 密钥生成逻辑已移动到 loadServerAKey 中，以支持动态文件名

	// 在 init 函数中解析命令行参数
	flag.StringVar(&adverserIPFlag, "advip", "", "指定 p2p_proxy 的 IP 地址")
	// PostgreSQL 配置覆盖参数
	// 格式: "{name}/{user_id}_{shop_id}/{target_ip}:{target_port}"
	flag.StringVar(&pgTargetFlag, "pg-target", "", "指定 PG 目标配置，格式: {name}/{user_id}_{shop_id}/{target_ip}:{target_port}")
	// VNC 配置覆盖参数
	flag.StringVar(&vncTargetFlag, "vnc-target", "", "指定 VNC 目标配置，格式: {name}/{user_id}_{shop_id}/{target_ip}:{target_port}")
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

func main() {
	//antigravity add 2026-01-23 19:18:54
	// === 全局 Panic 恢复机制 ===
	// 捕获所有未处理的 panic，记录详细堆栈信息，防止程序突然崩溃退出
	defer func() {
		if r := recover(); r != nil {
			// 获取堆栈信息
			buf := make([]byte, 4096)
			n := runtime.Stack(buf, false)
			stackTrace := string(buf[:n])

			// 记录错误日志
			log.Printf("🔴🔴🔴 程序发生严重错误 (Panic) 🔴🔴🔴")
			log.Printf("错误信息: %v", r)
			log.Printf("堆栈跟踪:\n%s", stackTrace)

			// 可选：写入独立的崩溃日志文件
			crashLogFile := fmt.Sprintf("crash_%s.log", time.Now().Format("20060102_150405"))
			crashContent := fmt.Sprintf("时间: %s\n错误: %v\n堆栈:\n%s",
				time.Now().Format("2006-01-02 15:04:05"), r, stackTrace)
			os.WriteFile(crashLogFile, []byte(crashContent), 0644)

			log.Printf("💾 崩溃日志已保存到: %s", crashLogFile)
			log.Printf("⚠️ 程序即将退出，请检查日志并修复问题后重新启动")

			// 给日志缓冲区时间写入
			time.Sleep(500 * time.Millisecond)
		}
	}()
	// === 全局 Panic 恢复机制结束 ===

	initMemTuning() // ✅ 新增：初始化内存调优

	// 在main函数中启动pprof服务器（可选，调试时使用）
	// go func() {
	// 	log.Printf("pprof listening on :%s\n", pprofHttpPort)
	// 	http.ListenAndServe(fmt.Sprintf(":%s", pprofHttpPort), nil)
	// }()

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
		go startHostConnector(SupertouchPCDataIP, AgentClientsidePort)

		// 阻塞主线程
		select {}
	}

}
