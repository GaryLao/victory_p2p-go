---
description: Build p2p_proxy using the required Go 1.25 version
---

To build the p2p_proxy project, you MUST use the specific Go 1.25 binary located at `W:\sdk\GO\go1.25.5\bin\go.exe`.

Steps:

1. Navigate to the p2p_proxy directory:
   `cd w:\Workspaces\GolandProjects\P2P\cmd\p2p_proxy`

2. Run the build command using the specific binary:
   // turbo
   `W:\sdk\GO\go1.25.5\bin\go.exe build -o ..\..\bin\p2p_proxy.exe`

3. Verify success by checking the existance of `..\..\bin\p2p_proxy.exe`.
