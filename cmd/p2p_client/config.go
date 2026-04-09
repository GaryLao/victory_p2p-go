package main

import (
	"path/filepath"
)

// getSupertouchPCDataIP 从 Data/SystemPara.ini 读取 IP
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
