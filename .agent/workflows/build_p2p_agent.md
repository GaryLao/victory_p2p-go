---
description: Build p2p_agent using the required Go 1.20 version
---

To build the p2p_agent project, you MUST use the specific Go 1.20 binary located at `W:\sdk\GO\go1.20.14\bin\go.exe`.

Steps:

1. Navigate to the p2p_agent directory:
   `cd w:\Workspaces\GolandProjects\P2P\cmd\p2p_agent`

2. Run the build command using the specific binary:
   // turbo
   `W:\sdk\GO\go1.20.14\bin\go.exe build -o ..\..\bin\p2p_agent.exe`

3. Verify success by checking the existance of `..\..\bin\p2p_agent.exe`.
