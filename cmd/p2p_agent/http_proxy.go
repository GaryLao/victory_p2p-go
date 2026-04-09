package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"time"

	"github.com/libp2p/go-libp2p/core/host"
	"github.com/libp2p/go-libp2p/core/network"
	"github.com/libp2p/go-libp2p/core/peer"
	"github.com/libp2p/go-libp2p/core/protocol"
)

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

// 修改：接收 host 和 serverPID 参数
func startLocalHttpProxy(h host.Host, serverPID peer.ID) {
	// === 1. 记录启动时间 (用于宽限期计算) ===
	// startTime := time.Now()
	// ======================================

	// lzm common 2025-12-16 16:57:31
	// targetDomain := "shop.4080517.com"

	log.Printf("✅ P2P Socket 代理启动: 监听 :"+AgentProxyHttpPort+" -> P2P Tunnel -> %s:{80,443}", h.Addrs())
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
			s, err := h.NewStream(context.Background(), serverPID, protocol.ID(TunnelProtocol))
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
		// === CORS 跨域支持 ===
		//antigravity add 2026-01-23 18:38:45
		// 设置 CORS 响应头，允许跨域请求
		origin := r.Header.Get("Origin")
		if origin != "" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Access-Control-Allow-Credentials", "true")
		} else {
			w.Header().Set("Access-Control-Allow-Origin", "*")
		}
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept, Origin")
		w.Header().Set("Access-Control-Max-Age", "86400") // 预检请求缓存24小时

		// 处理 OPTIONS 预检请求
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		// === CORS 跨域支持结束 ===

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
		// // if !isProxyOnline.Load() {
		// // 	// 记录日志可选，避免刷屏
		// // 	// log.Printf("⚠️ [熔断] 代理未连接，拒绝请求: %s", r.URL.Path)
		// // 	http.Error(w, "P2P Proxy Unavailable - Connection Lost", http.StatusServiceUnavailable)
		// // 	return
		// // }

		// === 1. 读取并缓存 Request Body ===
		// lzm modify 2026-01-09 17:10:14
		// 用带池化缓冲区的 copyBuffered 将请求体流式拷到 bytes.Buffer，
		// 		并用 http.MaxBytesReader 限制最大体积（示例 10MB）。
		// 		避免一次性把整个请求体读入内存。
		// bodyBytes, err := io.ReadAll(r.Body)
		bodyBytes, err := readRequestBodySafely(w, r)

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

		if P2PShowDetail == 1 {
			if r.URL.Path == "/index.php" {
				log.Printf("代理启动: "+AgentProxyHttpPort+" -> "+"P2P Tunnel -> %s://%s%s?%s", targetScheme, targetHost, r.URL.Path, query.Encode())
			} else {
				log.Printf("代理启动: "+AgentProxyHttpPort+" -> "+"P2P Tunnel -> %s://%s%s", targetScheme, targetHost, r.URL.Path)
			}
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

		// === 转发到p2p_proxy后，如果p2p_proxy没超时返回或返回400或500等失败信息时 ，尝试直接访问 ===

		// lzm modify 2025-12-16 16:57:31
		//
		// 如果是 HTTPS (443)，Transport 会自动进行 TLS 握手
		// rp.ServeHTTP(w, rWithCtx)
		//
		// 直接调用 rp.ServeHTTP 会导致无法捕获 Transport 层的网络错误
		// 以及业务层面的 HTTP 错误 (4xx, 5xx)，因此我们需要自定义 ModifyResponse 和 ErrorHandler。
		// 这样可以实现更灵活的错误处理和回退逻辑。
		// 例如：
		// 1. 如果网络错误（如连接超时、拒绝等），调用 ErrorHandler
		// 2. 如果响应状态码是 4xx 或 5xx，通过 ModifyResponse 返回错误，触发 ErrorHandler
		//
		// 这样，无论是网络层面的问题，还是业务层面的错误，我们都能统一处理并尝试直连。
		// 例如：
		// - 网络错误：p2p_proxy 不可达、连接超时等
		// - 业务错误：p2p_proxy 返回 502 Bad Gateway、504 Gateway Timeout 等
		//
		// 这样设计的好处是：
		// - 提高了代理的健壮性和容错能力
		// - 允许在代理失败时自动回退到直接访问，提升用户体验
		//
		// 注意事项：
		// - 确保 ModifyResponse 中关闭不需要的响应体，避免资源泄漏
		// - ErrorHandler 中的逻辑应尽量简洁，避免复杂操作导致二次错误

		// 1. 创建 rp 的浅拷贝 (Shallow Copy)
		// ReverseProxy 是结构体，直接赋值会复制其中的配置字段。
		// 这样做是为了给当前请求单独绑定 ErrorHandler，而不影响其他并发请求或全局 rp 对象。
		proxy := *rp

		// 返回 400 以上状态码时，直接发给客户端，不再尝试直连
		// 因为这些状态码通常表示客户端请求有问题，直连也无法解决
		// 例如：404 Not Found, 403 Forbidden 等
		// if r.URL.Path == "/index.php" {
		// 	log.Printf("P2P Tunnel 访问返回状态码 %d，直接返回给客户端: %s://%s?%s", resp.StatusCode, targetScheme, targetHost, r.URL.Path, query.Encode())
		// } else {
		// 	log.Printf("P2P Tunnel 访问返回状态码 %d，直接返回给客户端: %s://%s%s", resp.StatusCode, targetScheme, targetHost, r.URL.Path)
		// }
		//
		// // 2. 配置 ModifyResponse：拦截业务层面的失败 (4xx, 5xx)
		// proxy.ModifyResponse = func(resp *http.Response) error {
		// 	// 如果返回的状态码是 400 或以上 (如 404, 500, 502, 503)
		// 	// 我们返回一个 error，这会这会导致 ReverseProxy 停止处理并调用 ErrorHandler
		// 	if resp.StatusCode >= 400 {
		// 		// 必须显式关闭 resp.Body，因为我们决定不转发它了
		// 		resp.Body.Close()
		// 		return fmt.Errorf("upstream returned status %d", resp.StatusCode)
		// 	}
		// 	return nil
		// }

		// 3. 配置 ErrorHandler：统一处理网络错误和上面拦截的状态码错误
		// 原因：
		// 		连接层错误（如拨号失败）会触发 ErrorHandler。
		// 		传输层错误（如读取响应体中断）会触发 ErrorHandler。
		// 		业务层错误（如 502/404）如果你配置了 ModifyResponse 返回 error，也会触发 ErrorHandler。
		// 结论：
		// 		原来代码中通过 errContainer 在 ServeHTTP 结束后再去检查错误的逻辑（第 5 步）就变得完全多余了，
		// 		而且可能会导致双重处理。现在的 ErrorHandler 才是标准且统一的错误处理入口。
		proxy.ErrorHandler = func(rw http.ResponseWriter, req *http.Request, err error) {

			// 在这里记录日志（可选）
			// log.Printf("⚠️ 代理请求失败或被拦截: %v, 转为尝试直接访问", err)

			// 关键：此时 Headers 尚未发送给客户端，ResponseWriter 是干净的
			// 调用降级函数，由 tryDirectAccess 来接管处理请求
			tryDirectAccess(targetScheme, targetDomain, targetPort, rw, req, bodyBytes, "⚠️ [ErrorHandler] P2P 隧道失败")

		}

		// 4. 发起代理
		proxy.ServeHTTP(w, rWithCtx)

		// === 结束 ===

		// lzm modify 2026-01-09 17:54:38
		// 改为在上面的 proxy.ErrorHandler 进行错误处理和回退
		// 避免再次检测到错误并第二次调用 tryDirectAccess，导致程序报错 http: multiple response.WriteHeader（多次写入响应头）。
		//
		// // === 5. 错误处理与回退 (可选) ===
		// // errContainer.Err 它捕获的是：连接阶段的错误 这一逻辑通常写在你的 DialContext（自定义拨号）里。
		// // 		如果无法建立 P2P 隧道、连接超时、或者 Peer ID 找不到，DialContext 会报错并将错误赋值给 errContainer.Err。
		// // 		此时还没有收到任何 HTTP 响应。
		// // 它不包含：HTTP 状态码 (4xx, 5xx) 如果成功建立了 P2P连接，
		// // 		并且 p2p_proxy 返回了 500 Internal Server Error 或 404 Not Found，
		// // 		对于 Go 的 ReverseProxy 来说，这是一次成功的网络转发（因为它成功拿到了对方的响应），
		// // 		此时 errContainer.Err 通常为 nil。
		// if errContainer.Err != nil {
		// 	// log.Printf("⚠️ P2P 隧道失败，尝试直接访问: %v", errContainer.Err)
		// 	// 如果 P2P 失败，尝试本地直接访问 (Direct Access)
		// 	// 注意：如果目标是内网域名，本地直接访问可能也会失败
		// 	tryDirectAccess(targetScheme, targetDomain, targetPort, w, r, bodyBytes, "⚠️ P2P 隧道失败")
		// } else {
		// 	// log.Printf("✅ P2P Tunnel 访问成功: %s", r.URL.Path)
		//
		// 	// if r.URL.Path == "/index.php" {
		// 	// 	log.Printf("✅ P2P Tunnel 访问成功 %s://%s?%s", targetScheme, targetHost, r.URL.Path, query.Encode())
		// 	// } else {
		// 	// 	log.Printf("✅ P2P Tunnel 访问成功 %s://%s%s", targetScheme, targetHost, r.URL.Path)
		// 	// }
		// }

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
		// cert, err := generateSelfSignedCert()
		cert, err := getCachedSelfSignedCert()
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

	// io.Copy(w, resp.Body)
	if _, err := copyBuffered(w, resp.Body); err != nil && err != io.EOF {
		log.Printf("❌ 写响应体失败: %v", err)
	}
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
