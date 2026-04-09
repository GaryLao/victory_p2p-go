package main

// UpdateMessage 副机接收的更新消息结构
type UpdateMessage struct {
	Action     string `json:"action"`
	PackageURL string `json:"package_url"`
	Version    string `json:"version,omitempty"`
	Notes      string `json:"notes,omitempty"`
}
