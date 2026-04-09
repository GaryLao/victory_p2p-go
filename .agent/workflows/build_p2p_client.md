---
description: Build p2p_client using the required Go 1.10 version
---

To build the p2p_client project, you MUST use the specific Go 1.10 binary located at `W:\sdk\GO\go1.10\bin\go.exe`.
Note: Go 1.10 does NOT support go modules. Do not run `go mod tidy` or sets `GO111MODULE=on`.

Steps:

1. Navigate to the p2p_client directory:
   `cd w:\Workspaces\GolandProjects\P2P\cmd\p2p_client`

2. Run the build command using the specific binary:
   // turbo
   `W:\sdk\GO\go1.10\bin\go.exe build -o ..\..\bin\p2p_client.exe`

3. Verify success by checking the existance of `..\..\bin\p2p_client.exe`.
