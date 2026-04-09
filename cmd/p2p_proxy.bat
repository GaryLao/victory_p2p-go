@echo off
setlocal

REM === 配置区：只需修改这里即可适配不同环境 ===
REM 只有go1.20才能在windows 7运行
set "GO_BIN=W:\sdk\GO\go1.25.5\bin\go.exe"
set "GO_DIR=p2p_proxy"
set "GO_EXE=p2p_proxy.exe"
REM ============================================

REM 获取脚本所在目录，确保路径可靠
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%%GO_DIR%" || (
    echo Error: Directory '%GO_DIR%' not found.
    exit /b 1
)

REM 初始化标志
set DO_CLEAN=0
set DO_TIDY=0

REM 解析命令行参数（支持 clean / tidy，顺序无关，不区分大小写）
:parse_args
if "%~1" == "" goto :done_args
if /i "%~1" == "clean" set DO_CLEAN=1
if /i "%~1" == "tidy"  set DO_TIDY=1
shift
goto :parse_args
:done_args

REM 检查 go 是否存在
if not exist "%GO_BIN%" (
    echo [ERROR] Go binary not found at: %GO_BIN%
    exit /b 1
)

REM 执行 go clean -modcache（如果指定）
if %DO_CLEAN%==1 (
    echo [INFO] Running 'go clean -modcache'...
    "%GO_BIN%" clean -modcache
    if errorlevel 1 (
        echo [ERROR] go clean failed.
        goto :finish
    )
)

REM 执行 go mod tidy（如果指定）
if %DO_TIDY%==1 (
    echo [INFO] Running 'go mod tidy'...
    "%GO_BIN%" mod tidy
    if errorlevel 1 (
        echo [ERROR] go mod tidy failed.
        goto :finish
    )
)

REM 设置目标平台（Windows 64位）
set GOOS=windows
set GOARCH=amd64

REM 编译指定入口（不指定main.go 代表编译的文件在整个目录，这样就可以引用console_windows.go和console_unix.go）
echo [INFO] Building %GO_EXE%...
set GO111MODULE=on
"%GO_BIN%" build -o ..\..\bin\%GO_EXE%
if errorlevel 1 (
    echo [ERROR] Build failed.
    goto :finish
)

echo [SUCCESS] Build completed successfully.

:finish
cd /d "%SCRIPT_DIR%"
endlocal
exit /b 0