package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unicode/utf16"
	"unsafe"
)

// shouldStartUpdate 返回是否可以开始更新；若返回 true 会把 key 标记为正在进行
func shouldStartUpdate(key string) bool {
	updateMu.Lock()
	defer updateMu.Unlock()

	now := time.Now()
	// 如果已有进行中的更新
	if _, ok := updatesInProgress[key]; ok {
		return false
	}
	// 如果最近已经尝试过且尚在冷却期内
	if t, ok := lastAttempt[key]; ok {
		if now.Sub(t) < updateDedupWindow {
			return false
		}
	}
	// 标记为进行中并记录尝试时间
	updatesInProgress[key] = struct{}{}
	lastAttempt[key] = now
	return true
}

// finishUpdate 清理进行中标记
func finishUpdate(key string) {
	updateMu.Lock()
	defer updateMu.Unlock()
	delete(updatesInProgress, key)
}

// handleUpdate 解析并处理更新（示例：下载并保存到 Data/updates/<version>）
func handleUpdate(msg UpdateMessage, agentConn net.Conn) (string, error) {
	// === 用于测试 ===
	if msg.Notes != "" && strings.HasPrefix(msg.Notes, "test=") {
		sendUpdateStatus(agentConn, true, "download", 0, "开始下载")
		if msg.Notes == "test=1" {
			return "", fmt.Errorf("模拟下载失败")
		}
		sendUpdateStatus(agentConn, true, "download", 10, "开始安装")
		if msg.Notes == "test=2" {
			return "", fmt.Errorf("模拟安装失败")
		}
		sendUpdateStatus(agentConn, false, "idle", 100, "done")
		if msg.Notes == "test=3" {
			return "", fmt.Errorf("模拟安装完成")
		}
	}
	// =================

	// 使用版本或 package url 作为去重 key（两者都为空时使用时间戳）
	key := msg.Version
	if key == "" {
		key = msg.PackageURL
	}
	if key == "" {
		key = time.Now().Format("20060102_150405")
	}

	// 去重/并发保护
	if !shouldStartUpdate(key) {
		return "", fmt.Errorf("更新已在进行或最近已尝试，请稍后重试")
	}
	// 确保在退出时清理标记
	defer finishUpdate(key)

	//
	if msg.PackageURL == "" {
		// log.Printf("⚠️ 收到更新通知但未提供 package_url")
		return "", fmt.Errorf("❌ 收到更新通知但未提供 package_url")
	}
	ver := msg.Version
	if ver == "" {
		ver = time.Now().Format("20060102_150405")
	}

	// // 可执行文件路径 -> 可执行文件目录 -> 上一级目录
	// exePath, err := os.Executable()
	// if err != nil {
	// 	return "", fmt.Errorf("❌ 获取可执行文件路径失败: %v", err)
	// }
	// exeDir := filepath.Dir(exePath)
	// parentDir := filepath.Dir(exeDir)
	//
	// updateDir := filepath.Join(parentDir, "liveupdate")
	// if err := os.MkdirAll(updateDir, 0755); err != nil {
	// 	return "", fmt.Errorf("❌ 创建更新目录失败: %v", err)
	// }
	//
	// // 下载文件并保存为 update.pkg
	// dst := filepath.Join(updateDir, "NativeSync_client.7z")
	// log.Printf("⬇️ 开始下载更新 %s -> %s", msg.PackageURL, dst)
	// if err := downloadFile(msg.PackageURL, dst); err != nil {
	// 	// log.Printf("❌ 下载更新失败: %v", err)
	// 	return "", fmt.Errorf("❌ 下载更新失败: %v", err)
	// }
	// log.Printf("✅ 下载完成: %s (version=%s)", dst, ver)

	// === 调用 liveupdate_download.py 下载更新 ===
	// 要运行的脚本名
	pyFile := "liveupdate_download.py"

	// 当前可执行文件所在目录
	exePath, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("❌ 获取可执行文件路径失败: %v", err)
	}
	exeDir := filepath.Dir(exePath)
	parentDir := filepath.Dir(exeDir)

	// 在 `handleUpdate` 中计算完 exeDir/parentDir 之后（在执行 python 脚本之前）插入如下调用：
	if ok, reason, err := precheckUpdate(msg, exeDir); err != nil {
		return "", fmt.Errorf("precheck error: %v", err)
	} else if !ok {
		// sendUpdateStatus(agentConn, false, "idle", 0, reason)
		return "", fmt.Errorf(reason)
	}

	// filepath.Clean 用来对路径做词法（纯文本）规范化：去掉多余的分隔符、处理 . 和 ..，并在 Windows 平台把 / 转为 \。
	// 它不访问文件系统、不解析符号链接，也不判断路径是否存在。
	// 构造 python.exe 路径： ..\python27\python.exe
	pythonExe := filepath.Clean(filepath.Join(parentDir, "python27", "python.exe"))

	// 构造脚本完整路径： PythonCode\restaurant_pos\liveupdate_download.py
	pyFull := filepath.Clean(filepath.Join(exeDir, "PythonCode", "restaurant_pos", pyFile))

	// 上报：开始下载
	sendUpdateStatus(agentConn, true, "download", 0, "开始下载")

	// 另一种方式：直接执行并等待（不最小化窗口）
	// cmd := exec.Command(pythonExe, pyFull)
	// 另一种方式：异步启动然后等待
	// err = runAsyncThenWait(pythonExe, pyFull)
	log.Printf("开始执行下载脚本：%s %s", pythonExe, pyFull)
	if err := runWithStartWait(pythonExe, pyFull); err != nil {
		return "", fmt.Errorf("❌ %s 执行失败: %v", pyFile, err)
	}
	dst := "NativeSync_client.7z"

	// === 下载完成，检查是否需要安装/替换 NativeSync 客户端 ===
	if NeedUpdateNativeSyncClientApp(exeDir, SupertouchPCDataIP) {
		// log.Printf("🔄 需要更新 NativeSync 客户端")

		// 在执行安装前：
		if err := runLiveUpdate(); err != nil {
			sendUpdateStatus(agentConn, false, "install", 0, "安装失败: "+err.Error())
			return "", err
		}

		sendUpdateStatus(agentConn, true, "download", 10, "开始安装")

		// 启动 LiveUpdate.exe 进行安装
		log.Printf("🚀 启动 LiveUpdate 进行安装")
		if err := runLiveUpdate(); err != nil {
			// log.Printf("❌ 启动 LiveUpdate 失败: %v", err)
			return "", fmt.Errorf("❌ 启动 LiveUpdate 失败: %v", err)
		}

		// 完成
		sendUpdateStatus(agentConn, false, "idle", 100, "done")
	} else {
		log.Printf("ℹ️ 不需要更新客户端")

		// 完成
		sendUpdateStatus(agentConn, false, "idle", 100, "ℹ️ 不需要更新客户端")
	}

	return dst, nil
}

// precheckUpdate 在开始下载/安装前做三项检查：
// 1) LiveUpdate.exe 是否在运行（使用 Toolhelp API）
// 2) parentDir\nativesync_client.exe 的修改时间 >= msg.Version 则不需升级
// 3) 枚举顶层窗口标题查找 "yippee_liveupdate_download"
func precheckUpdate(msg UpdateMessage, exeDir string) (bool, string, error) {
	if runtime.GOOS != "windows" {
		return true, "", nil
	}

	parentDir := filepath.Dir(exeDir)

	// 1) 检查 LiveUpdate.exe 是否在运行（使用 CreateToolhelp32Snapshot）
	running, err := isProcessRunning("LiveUpdate.exe")
	if err == nil && running {
		return false, "LiveUpdate.exe 正在运行（正在升级）", nil
	}
	// 若出错则继续执行后续检查（非致命）

	// 3) 检查窗口标题（通过 EnumWindows + GetWindowTextW）
	if found, _ := findWindowWithTitleSubstr("yippee_liveupdate_download"); found {
		return false, "检测到下载窗口 liveupdate_download（正在下载）", nil
	}

	// 2) 检查客户端 exe 修改时间
	// clientPath := filepath.Join(parentDir, "client.exe")
	// if fi, err := os.Stat(clientPath); err == nil {
	// 	if msg.Version != "" {
	// 		verTime, perr := time.Parse("20060102_150405", msg.Version)
	// 		if perr == nil {
	// 			if !fi.ModTime().Before(verTime) {
	// 				return false, "客户端文件修改时间 >= msg.Version，认为不需要升级", nil
	// 			}
	// 		}
	// 	}
	// }
	clientPath := filepath.Join(parentDir, "client.exe")

	const layout = "20060102_150405"
	const defaultStr = "20060102_150405"

	var clientMod time.Time
	if fi, err := os.Stat(clientPath); err == nil {
		clientMod = fi.ModTime()
	} else {
		// 文件不存在或无法访问时使用默认时间（2006-01-02 15:04:05）
		t, _ := time.Parse(layout, defaultStr)
		clientMod = t
	}

	if msg.Version != "" {
		verTime, perr := time.Parse(layout, msg.Version)
		if perr == nil {
			// 如果客户端修改时间 >= msg.Version，则认为不需要升级
			if !clientMod.Before(verTime) {
				return false, "客户端文件修改时间 >= msg.Version，认为不需要升级", nil
			}
		}
		// 解析失败则忽略时间比较（保守做法：继续升级）
	}

	return true, "", nil
}

// isProcessRunning 使用 Toolhelp API 枚举进程，查找给定可执行名（区分大小写）
func isProcessRunning(procName string) (bool, error) {
	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procCreateSnapshot := kernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32First := kernel32.NewProc("Process32FirstW")
	procProcess32Next := kernel32.NewProc("Process32NextW")
	procCloseHandle := kernel32.NewProc("CloseHandle")

	const TH32CS_SNAPPROCESS = 0x00000002

	type processEntry32 struct {
		dwSize              uint32
		cntUsage            uint32
		th32ProcessID       uint32
		th32DefaultHeapID   uintptr
		th32ModuleID        uint32
		cntThreads          uint32
		th32ParentProcessID uint32
		pcPriClassBase      int32
		dwFlags             uint32
		szExeFile           [260]uint16
	}

	h, _, err := procCreateSnapshot.Call(uintptr(TH32CS_SNAPPROCESS), uintptr(0))
	// 关键修复：将 syscall.InvalidHandle 转为 uintptr 后比较，避免类型不匹配
	if h == 0 || h == uintptr(syscall.InvalidHandle) {
		return false, err
	}
	defer procCloseHandle.Call(h)

	var pe processEntry32
	pe.dwSize = uint32(unsafe.Sizeof(pe))

	ret, _, _ := procProcess32First.Call(h, uintptr(unsafe.Pointer(&pe)))
	if ret == 0 {
		return false, nil
	}
	for {
		// convert szExeFile (UTF-16) to string
		n := 0
		for n < len(pe.szExeFile) && pe.szExeFile[n] != 0 {
			n++
		}
		exe := syscall.UTF16ToString(pe.szExeFile[:n])
		if strings.EqualFold(exe, procName) {
			return true, nil
		}
		ret, _, _ = procProcess32Next.Call(h, uintptr(unsafe.Pointer(&pe)))
		if ret == 0 {
			break
		}
	}
	return false, nil
}

// findWindowWithTitleSubstr 枚举顶层窗口并检查窗口标题是否包含子串（ASCII/UTF-16）
// 返回 (true, nil) 表示找到
func findWindowWithTitleSubstr(substr string) (bool, error) {
	user32 := syscall.NewLazyDLL("user32.dll")
	procEnumWindows := user32.NewProc("EnumWindows")
	procGetWindowTextW := user32.NewProc("GetWindowTextW")
	procIsWindowVisible := user32.NewProc("IsWindowVisible")

	found := false
	cb := syscall.NewCallback(func(hwnd uintptr, lparam uintptr) uintptr {
		// 可见性检查（可选）
		vis, _, _ := procIsWindowVisible.Call(hwnd)
		if vis == 0 {
			return 1 // continue
		}
		// 获取窗口文本长度（使用 GetWindowTextW，先分配缓冲）
		buf := make([]uint16, 256)
		n, _, _ := procGetWindowTextW.Call(hwnd, uintptr(unsafe.Pointer(&buf[0])), uintptr(len(buf)))
		if n == 0 {
			return 1
		}
		title := utf16.Decode(buf[:n])
		s := string(title)
		if strings.Contains(s, substr) {
			found = true
			return 0 // stop enumeration
		}
		return 1 // continue
	})

	// 调用 EnumWindows(cb, 0)
	_, _, err := procEnumWindows.Call(cb, 0)
	if err != syscall.Errno(0) && err != nil {
		// 在某些系统上 Call 会返回非零 err，但 enumeration 仍工作；这里只返回 nil 以兼容性为主
	}
	return found, nil
}

// 发送状态到 p2p_agent（简单的文本行协议）
func sendUpdateStatus(conn net.Conn, working bool, task string, progress int, info string) {
	if conn == nil {
		return
	}
	// 避免消息中包含换行或分隔符，做简单替换
	escape := func(s string) string {
		s = strings.Replace(s, "\n", " ", -1)
		s = strings.Replace(s, "\r", " ", -1)
		s = strings.Replace(s, "|", "/", -1)
		return s
	}
	w := "0"
	if working {
		w = "1"
	}
	line := "UPDATE_STATUS|" + w + "|" + escape(task) + "|" + strconv.Itoa(progress) + "|" + escape(info) + "\n"
	// 忽略写错误（可增强重试/缓冲）
	_, _ = conn.Write([]byte(line))
}

func runLiveUpdate() error {
	if runtime.GOOS != "windows" {
		return fmt.Errorf("unsupported platform")
	}

	// 可执行文件路径 -> 可执行文件目录 -> 上一级目录
	exePath, err := os.Executable()
	if err != nil {
		return err
	}
	exeDir := filepath.Dir(exePath)
	parentDir := filepath.Dir(exeDir)

	// 目标可执行文件： parentDir\LiveUpdate\LiveUpdate.exe
	livePath := filepath.Join(parentDir, "LiveUpdate", "LiveUpdate.exe")

	// 参数: "show=false" "downloadnow=false" "nativesync_client.exe"
	cmd := exec.Command(livePath, "show=false", "downloadnow=false", "nativesync_client.exe")
	// cmd := exec.Command(livePath, "show", "notdownload", "nativesync_client.exe")
	// 将工作目录设为 parentDir（与 Delphi 中的空目录参数相近）
	cmd.Dir = parentDir

	// 在 Windows 上确保显示窗口（创建新控制台）
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow:    false,
		CreationFlags: 0x10, // syscall.CREATE_NEW_CONSOLE,
	}

	// 异步启动，不阻塞当前进程（等价于 ShellExec 的行为）
	if err := cmd.Start(); err != nil {
		return err
	}
	return nil
}

// runWithStartWait 使用 `cmd /C start "" /MIN /WAIT ...`，调用 Run() 会等待命令及被 start 启动的子进程退出。
func runWithStartWait(pythonExe, pyFull string) error {
	cmd := exec.Command("cmd", "/C", "start", "", "/MIN", "/WAIT", pythonExe, pyFull)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run() // Run 会等待 cmd.exe 结束；带 /WAIT 时 cmd.exe 会等被启动的程序结束
}

// runDirectWait 直接执行可执行文件，Run() 会等待该进程退出。
func runDirectWait(pythonExe, pyFull string) error {
	cmd := exec.Command(pythonExe, pyFull)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run() // 等待 python 进程结束
}

// runAsyncThenWait 演示 Start() + Wait()（Start 异步返回，Wait 用来等待）
func runAsyncThenWait(pythonExe, pyFull string) error {
	cmd := exec.Command(pythonExe, pyFull)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		return err
	}
	return cmd.Wait() // 显式等待
}

// downloadFile 简单下载文件到目标路径
//
//	func downloadFile(url, dst string) error {
//		resp, err := http.Get(url)
//		if err != nil {
//			return err
//		}
//		defer func() {
//			if err := resp.Body.Close(); err != nil {
//				log.Printf("⚠️ 关闭响应体失败: %v", err)
//			}
//		}()
//		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
//			return fmt.Errorf("download failed status: %d", resp.StatusCode)
//		}
//		f, err := os.Create(dst)
//		if err != nil {
//			return err
//		}
//		defer func() {
//			if err := f.Close(); err != nil {
//				log.Printf("⚠️ 关闭文件失败: %v", err)
//			}
//		}()
//		_, err = io.Copy(f, resp.Body)
//		return err
//	}
//
// downloadFile 支持断点续传（使用 dst+".part" 作为临时文件，完成后原子重命名）
func downloadFile(url, dst string) error {
	tmp := dst + ".part"

	// 获取已下载大小（如果存在）
	var start int64 = 0
	if fi, err := os.Stat(tmp); err == nil {
		start = fi.Size()
	}

	// 构造请求
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return fmt.Errorf("创建请求失败: %v", err)
	}
	// 设置 Range 头（仅当已有部分文件时）
	if start > 0 {
		req.Header.Set("Range", "bytes="+strconv.FormatInt(start, 10)+"-")
	}
	// 可选：设置 User-Agent / Accept 等
	req.Header.Set("User-Agent", "P2P_Client/1.0")

	client := &http.Client{
		Timeout: 0, // 不设置超时以支持大文件（如需可设置合理超时）
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 处理状态码
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusPartialContent {
		return fmt.Errorf("unexpected HTTP status: %d", resp.StatusCode)
	}

	// 如果服务器返回 200 而我们之前已有部分文件，则必须从头覆盖（服务器不支持 Range）
	if resp.StatusCode == http.StatusOK && start > 0 {
		// truncate 临时文件
		if err := os.Truncate(tmp, 0); err != nil {
			// 尝试删除并重建
			_ = os.Remove(tmp)
		}
		start = 0
	}

	// 打开临时文件，写入（若续传，则以 append 模式并 seek 到末尾）
	f, err := os.OpenFile(tmp, os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("打开临时文件失败: %v", err)
	}
	defer func() {
		f.Sync()
		f.Close()
	}()

	if start > 0 {
		if _, err := f.Seek(start, io.SeekStart); err != nil {
			return fmt.Errorf("seek 失败: %v", err)
		}
	}

	// 复制响应体到文件（可以在这里加入进度回调）
	_, err = io.Copy(f, resp.Body)
	if err != nil {
		// 下载中断，保留 .part 以便下次续传
		return fmt.Errorf("写入临时文件失败: %v", err)
	}

	// 完成后关闭文件并重命名为目标文件（原子操作）
	if err := f.Close(); err != nil {
		return fmt.Errorf("关闭临时文件失败: %v", err)
	}
	if err := os.Rename(tmp, dst); err != nil {
		return fmt.Errorf("重命名临时文件失败: %v", err)
	}

	// 可选：设置文件修改时间为服务器返回的 Last-Modified（若需要）
	if lm := resp.Header.Get("Last-Modified"); lm != "" {
		if t, err := http.ParseTime(lm); err == nil {
			_ = os.Chtimes(dst, time.Now(), t)
		}
	}

	return nil
}

// NeedUpdateNativeSyncClientApp 检查是否需要更新 NativeSync 客户端
// 参数:
//
//	appDir - 应用程序运行目录（等价 Delphi 中的 gAppDir）
//	svrIP - 配置中的主机 IP（等价 Delphi 中的 gSupertouchPCDataIP_tt）
func NeedUpdateNativeSyncClientApp(appDir, svrIP string) bool {
	// 如果是本机/回环地址，服务器不需要更新副机
	if isLocalIPAddress(svrIP) {
		return false
	}

	// 检查 7za.exe 是否存在： ExtractFileDir(APP_DIR) + '\LiveUpdate\7z\7za.exe'
	sevenZip := filepath.Join(filepath.Dir(appDir), "LiveUpdate", "7z", "7za.exe")
	if _, err := os.Stat(sevenZip); os.IsNotExist(err) {
		return false
	}

	const appName = "NativeSync"

	// 读取本地 NativeSync_client_version 版本，默认 1.0.0
	localVer := "1.0.0"
	localVerFile := filepath.Join(appDir, appName+"_client_version")
	if b, err := ioutil.ReadFile(localVerFile); err == nil {
		if s := strings.TrimSpace(string(b)); s != "" {
			localVer = s
		}
	}

	// 读取 LiveUpdate\NativeSync_version 中的 client 文件和 version
	localVersionFilename := filepath.Join(filepath.Dir(appDir), "LiveUpdate", strings.ToLower(appName)+"_version")
	if _, err := os.Stat(localVersionFilename); os.IsNotExist(err) {
		return false
	}

	zipFile := readIniValue(localVersionFilename, appName+"_client", "file", "")
	_ = zipFile // 保留以备后用（与 Delphi 原逻辑一致）

	zipVer := readIniValue(localVersionFilename, appName+"_client", "version", "")
	if strings.TrimSpace(zipVer) == "" {
		zipVer = "1.0.0"
	}

	// 如果更新包版本高于本地版本，继续检查下载标记
	if compareVersion(zipVer, localVer) > 0 {
		downloadTagFilename := filepath.Join(filepath.Dir(appDir), "LiveUpdate", strings.ToLower(appName)+"_download_tag.ini")
		downSize := readIniValue(downloadTagFilename, appName+"_client", "down_size", "")
		totalSize := readIniValue(downloadTagFilename, appName+"_client", "total_size", "")

		if downSize != "" && downSize == totalSize {
			if n, err := strconv.Atoi(totalSize); err == nil && n > 0 {
				return true
			}
		}
	}

	return false
}

// compareVersion 比较两个版本字符串（如 "1.2.3"），
// 返回 1 如果 a>b，0 如果相等，-1 如果 a<b
func compareVersion(a, b string) int {
	as := strings.Split(a, ".")
	bs := strings.Split(b, ".")
	maxLen := len(as)
	if len(bs) > maxLen {
		maxLen = len(bs)
	}
	for i := 0; i < maxLen; i++ {
		ai := atoiOrZero(getPart(as, i))
		bi := atoiOrZero(getPart(bs, i))
		if ai > bi {
			return 1
		} else if ai < bi {
			return -1
		}
	}
	return 0
}

func getPart(parts []string, idx int) string {
	if idx < len(parts) {
		return parts[idx]
	}
	return "0"
}

func atoiOrZero(s string) int {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0
	}
	if v, err := strconv.Atoi(s); err == nil {
		return v
	}
	// 保险：去掉前导零后再试
	s = strings.TrimLeft(s, "0")
	if s == "" {
		return 0
	}
	v, _ := strconv.Atoi(s)
	return v
}
