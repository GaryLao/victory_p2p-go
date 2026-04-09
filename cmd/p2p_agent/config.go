package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"

	// "github.com/libp2p/go-libp2p/core/peer"

	"golang.org/x/sys/windows/registry"
	"golang.org/x/text/encoding/simplifiedchinese"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"

	p2pcrypto "github.com/libp2p/go-libp2p/core/crypto"
)

func loadServerAKey() p2pcrypto.PrivKey {
	// privKey := loadServerAKeyFromFile()
	// pubKey := privKey.GetPublic()
	// testID, _ := peer.IDFromPublicKey(pubKey)
	// log.Printf("测试：文件的PeerID = %s", testID)

	return loadServerAKeyFromReg()
}

func loadServerAKeyFromReg() p2pcrypto.PrivKey {
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

		priv, err := p2pcrypto.UnmarshalPrivateKey(versionedKey.KeyData)
		if err != nil {
			log.Fatalf("❌ 致命错误：注册表中的密钥解析失败: %v", err)
		}

		log.Printf("✅ 已从注册表加载本机身份密钥")
		return priv
	}

	// --- 如果密钥不存在，则生成并保存 ---
	log.Printf("ℹ️ 注册表中未找到密钥，正在为本机生成唯一身份密钥...")
	priv, _, err := p2pcrypto.GenerateKeyPair(p2pcrypto.ECDSA, 256)
	if err != nil {
		log.Fatalf("❌ 致命错误：生成新密钥失败: %v", err)
	}

	// 序列化密钥
	privBytes, err := p2pcrypto.MarshalPrivateKey(priv)
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

func loadServerAKeyFromFile() p2pcrypto.PrivKey {
	userId := getUserIDFromRegistry()
	shopid := getShopIDFromIni()
	shoptag := fmt.Sprintf("%s_%s", userId, shopid)

	keyFileName := fmt.Sprintf(""+AppName+"_%s.key", shoptag)

	if _, err := os.Stat(keyFileName); os.IsNotExist(err) {
		log.Printf("密钥文件 %s 不存在，正在为本机生成唯一身份密钥...", keyFileName)
		priv, _, err := p2pcrypto.GenerateKeyPair(p2pcrypto.ECDSA, 256)
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

	priv, err := p2pcrypto.UnmarshalPrivateKey(versionedKey.KeyData)
	if err != nil {
		log.Fatalf("致命错误：私钥解析失败: %v", err)
	}

	log.Printf("已加载本机身份密钥: %s", keyFileName)
	return priv
}

func loadServerBKey() p2pcrypto.PrivKey {
	// 尝试从 keys 目录读取
	keysDir := "keys"
	keyPath := filepath.Join(keysDir, BkeyFileName)

	data, err := os.ReadFile(keyPath)
	if err != nil {
		// 兼容旧逻辑：如果 keys 目录没有，尝试当前目录
		data, err = os.ReadFile(BkeyFileName)
		if err != nil {
			log.Fatalf("致命错误：无法读取私钥文件: %v", err)
		}
	}

	var versionedKey VersionedKey
	if err := json.Unmarshal(data, &versionedKey); err != nil {
		if len(data) > 12 && string(data[:12]) == "LIBP2PKEY-1.0" {
			priv, err := p2pcrypto.UnmarshalPrivateKey(data[12:])
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

	priv, err := p2pcrypto.UnmarshalPrivateKey(versionedKey.KeyData)
	if err != nil {
		log.Fatalf("致命错误：私钥解析失败: %v", err)
	}
	return priv
}

// parseVncTargetFlag 解析 -vnc-target 参数
// 格式: "{name}/{user_id}_{shop_id}/{target_ip}:{target_port}"
// 返回: name, user_id, shop_id, target_ip, target_port
func parseVncTargetFlag(flag string) (name, userID, shopID, targetIP string, targetPort int) {
	if flag == "" {
		return
	}

	// 按 "/" 分割
	parts := strings.Split(flag, "/")
	if len(parts) >= 1 {
		name = parts[0]
	}
	if len(parts) >= 2 {
		// 解析 user_id_shop_id
		userShop := parts[1]
		if idx := strings.LastIndex(userShop, "_"); idx > 0 {
			userID = userShop[:idx]
			shopID = userShop[idx+1:]
		}
	}
	if len(parts) >= 3 {
		// 解析 target_ip:target_port
		ipPort := parts[2]
		if idx := strings.LastIndex(ipPort, ":"); idx > 0 {
			targetIP = ipPort[:idx]
			if p, err := strconv.Atoi(ipPort[idx+1:]); err == nil {
				targetPort = p
			}
		} else {
			targetIP = ipPort
		}
	}
	return
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

	// 如果指定了 -vnc-target 参数，解析并应用覆盖
	if vncTargetFlag != "" {
		name, userID, shopID, targetIP, targetPort := parseVncTargetFlag(vncTargetFlag)

		// 根据 name 查找匹配的配置项
		var matched *VNCTargetConfig
		var matchedIdx int = -1
		for i := range targets {
			if targets[i].Name == name {
				matched = &targets[i]
				matchedIdx = i
				break
			}
		}

		if matched == nil {
			return nil, fmt.Errorf("未找到名称为 '%s' 的 VNC 配置", name)
		}

		// 应用命令行覆盖
		if userID != "" {
			matched.UserID = userID
		}
		if shopID != "" {
			matched.ShopID = shopID
		}
		if targetIP != "" {
			matched.TargetIP = targetIP
		}
		if targetPort > 0 {
			matched.TargetPort = targetPort
		}

		log.Printf("✅ [VNC配置] 使用配置 '%s': user_id=%s shop_id=%s target_ip=%s target_port=%d",
			matched.Name, matched.UserID, matched.ShopID, matched.TargetIP, matched.TargetPort)

		// 只返回匹配的配置项
		return []VNCTargetConfig{targets[matchedIdx]}, nil
	}

	return targets, nil
}

// parsePgTargetFlag 解析 -pg-target 参数
// 格式: "{name}/{user_id}_{shop_id}/{target_ip}:{target_port}"
// 返回: name, user_id, shop_id, target_ip, target_port
func parsePgTargetFlag(flag string) (name, userID, shopID, targetIP string, targetPort int) {
	if flag == "" {
		return
	}

	// 按 "/" 分割
	parts := strings.Split(flag, "/")
	if len(parts) >= 1 {
		name = parts[0]
	}
	if len(parts) >= 2 {
		// 解析 user_id_shop_id
		userShop := parts[1]
		if idx := strings.LastIndex(userShop, "_"); idx > 0 {
			userID = userShop[:idx]
			shopID = userShop[idx+1:]
		}
	}
	if len(parts) >= 3 {
		// 解析 target_ip:target_port
		ipPort := parts[2]
		if idx := strings.LastIndex(ipPort, ":"); idx > 0 {
			targetIP = ipPort[:idx]
			if p, err := strconv.Atoi(ipPort[idx+1:]); err == nil {
				targetPort = p
			}
		} else {
			targetIP = ipPort
		}
	}
	return
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

	// 如果指定了 -pg-target 参数，解析并应用覆盖
	if pgTargetFlag != "" {
		name, userID, shopID, targetIP, targetPort := parsePgTargetFlag(pgTargetFlag)

		// 根据 name 查找匹配的配置项
		var matched *PostgresTargetConfig
		var matchedIdx int = -1
		for i := range targets {
			if targets[i].Name == name {
				matched = &targets[i]
				matchedIdx = i
				break
			}
		}

		if matched == nil {
			return nil, fmt.Errorf("未找到名称为 '%s' 的 PG 配置", name)
		}

		// 应用命令行覆盖
		if userID != "" {
			matched.UserID = userID
		}
		if shopID != "" {
			matched.ShopID = shopID
		}
		if targetIP != "" {
			matched.TargetIP = targetIP
		}
		if targetPort > 0 {
			matched.TargetPort = targetPort
		}

		log.Printf("✅ [PG配置] 使用配置 '%s': user_id=%s shop_id=%s target_ip=%s target_port=%d",
			matched.Name, matched.UserID, matched.ShopID, matched.TargetIP, matched.TargetPort)

		// 只返回匹配的配置项
		return []PostgresTargetConfig{targets[matchedIdx]}, nil
	}

	return targets, nil
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

func SavePrivateKeyToFile(filename string, priv p2pcrypto.PrivKey) error {
	privBytes, err := p2pcrypto.MarshalPrivateKey(priv)
	if err != nil {
		return fmt.Errorf("密钥序列化失败: %v", err)
	}

	versionedKey := VersionedKey{
		Version: 1,
		KeyData: privBytes,
		Magic:   []byte("LIBP2PKEY-1.0"),
	}

	data, err := json.Marshal(versionedKey)
	if err != nil {
		return fmt.Errorf("密钥 JSON 编码失败: %v", err)
	}

	return os.WriteFile(filename, data, 0600)
}
