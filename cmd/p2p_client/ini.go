package main

import (
	"bufio"
	"io"
	"os"
	"strings"
	"syscall"
	"unsafe"

	// 适合g1.10的版本，版本的构建年份一般是2018年或2019年
	"golang.org/x/text/encoding/simplifiedchinese"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"
)

// readIniValue 从文件读取 ini 值，默认根据系统 ACP 在 Windows 上做转换。
// 参数 useACP 可选，传 false 禁用 ACP 检测（按 UTF-8 处理）。
func readIniValue(path, targetSection, targetKey string, defaultVal string, useACP ...bool) string {
	// use := true
	// if len(useACP) > 0 {
	// 	use = useACP[0]
	// }
	//
	// data, err := ioutil.ReadFile(path)
	// if err != nil {
	// 	return defaultVal
	// }
	//
	// var text string
	// if use && runtime.GOOS == "windows" {
	// 	if decoded, derr := decodeWindowsANSI(data); derr == nil {
	// 		text = decoded
	// 	} else {
	// 		// 回退：假定 UTF-8
	// 		text = string(data)
	// 	}
	// } else {
	// 	// 非 Windows 或显式禁用 ACP：假定 UTF-8
	// 	text = string(data)
	// }
	// scanner := bufio.NewScanner(strings.NewReader(text))

	// 可选参数：默认 useACP = true
	file, err := os.Open(path)
	if err != nil {
		return defaultVal
	}
	defer file.Close()

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

	//
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

// decodeWindowsANSI 使用 WinAPI 将 ANSI (ACP) 编码字节转换为 UTF-8 字符串。
// 依赖 syscall 和 unsafe，适用于 Windows 平台。
func decodeWindowsANSI(b []byte) (string, error) {
	if len(b) == 0 {
		return "", nil
	}

	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procGetACP := kernel32.NewProc("GetACP")
	procMB := kernel32.NewProc("MultiByteToWideChar")

	// 获取当前 ANSI code page
	ret, _, _ := procGetACP.Call()
	cp := uintptr(ret)

	// 先获取需要的 UTF-16 长度
	r1, _, err := procMB.Call(cp, 0, uintptr(unsafe.Pointer(&b[0])), uintptr(len(b)), 0, 0)
	if r1 == 0 {
		return "", err
	}
	n := int(r1)

	// 分配缓冲并执行转换
	buf := make([]uint16, n+1) // 多分配一个 0 结尾
	r2, _, err2 := procMB.Call(cp, 0, uintptr(unsafe.Pointer(&b[0])), uintptr(len(b)), uintptr(unsafe.Pointer(&buf[0])), uintptr(n))
	if r2 == 0 {
		return "", err2
	}

	// 转为 Go string（UTF-8）
	return syscall.UTF16ToString(buf), nil
}
