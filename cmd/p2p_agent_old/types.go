package main

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
