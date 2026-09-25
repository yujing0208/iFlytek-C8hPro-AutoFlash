@echo off
chcp 936 >nul
setlocal EnableDelayedExpansion
title 刷机自动化 1/3 - 解锁 BL 锁（讯飞 C8hPro）

echo ============================================================
echo   刷机自动化   步骤 1 / 3
echo   解锁 Bootloader（解 BL 锁）
echo ============================================================
echo.
echo   【本步骤会做什么】
echo     写入解锁版 uboot 与去校验版 splloader，
echo     并清空 userdata 分区（相当于恢复出厂设置）。
echo.
echo   【做完之后】
echo     设备可以刷入第三方系统（GSI）。
echo     接着请运行：  2-刷入GSI.bat
echo.
echo ============================================================
echo.

rem ===== 可选提速：默认关闭。流程跑通后，改成 blk_size 65535 可加快写入 =====
set "BLK="

cd /d "%~dp0..\SPRD" 2>nul
if not exist "spd_dump.exe" goto ERR_ENV

net session >nul 2>&1
if not errorlevel 1 goto IS_ADMIN

echo   [权限] 安装驱动需要管理员权限，正在请求提升……
>"%TEMP%\__uac.vbs" echo Set U = CreateObject("Shell.Application"): U.ShellExecute "%~f0", "", "", "runas", 1
cscript //nologo "%TEMP%\__uac.vbs" >nul 2>&1
del "%TEMP%\__uac.vbs" >nul 2>&1
exit /b

:IS_ADMIN

echo   [1/3] 检查紫光展锐 USB 驱动……
set "DRV="
if exist "%SystemRoot%\System32\drivers\sprdvcom.sys" set "DRV=1"
if exist "%SystemRoot%\System32\drivers\sprdvmdm.sys" set "DRV=1"
for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\sprdvcom.inf_*") do set "DRV=1"

if defined DRV (
    echo         已检测到驱动，跳过安装。
    echo.
) else (
    echo         未检测到驱动，开始自动安装……
    call :INSTALL_DRIVER
    if errorlevel 1 (
        echo.
        echo   [警告] 驱动未能确认安装成功。
        echo          若刷机时提示找不到设备，请手动运行：
        echo          Driver_R4.21.3201\Driver_R4.21.3201\DriversForWin10\DriverSetup.exe
        echo.
        pause
    ) else (
        echo         驱动安装完成。
        echo.
    )
)

echo   [2/3] 检查所需文件……
set "MISS="
for %%F in (uboot_c8hpro_unlock.bin splloader_c8hpro_disverify.bin fdl1.bin fdl2.bin) do (
    if exist "_file\%%F" (
        echo         [OK]   %%F
    ) else (
        echo         [缺少] %%F
        set "MISS=1"
    )
)
if defined MISS goto ERR_FILES
echo.

echo   [3/3] 等待设备接入（进入 BROM 模式）
echo.
echo         1. 先把平板【关机】
echo         2. 长按【音量减】键不要松手
echo         3. 保持按住，把 USB 数据线插入电脑
echo.
echo         识别到设备后会自动开始，最长等待 300 秒。
echo         等待期间请不要松手、不要拔线。
echo.
echo         准备好后按任意键，程序开始等待设备……
pause >nul
title 等待设备中 - 请长按音量减键并插入数据线
echo.
echo   ============================================================
echo     正在等待设备连接：请长按【音量减】键不放，
echo     保持按住状态，把数据线插入电脑……
echo   ============================================================
echo.
echo   正在写入 uboot / splloader 并清空 userdata，请勿拔线……
echo.
spd_dump --wait 300 fdl _file\fdl1.bin 0x5500 fdl _file\fdl2.bin 0x9efffe00 exec %BLK% w uboot _file\uboot_c8hpro_unlock.bin w splloader _file\splloader_c8hpro_disverify.bin e userdata reset
set "RC=%errorlevel%"
title 刷机自动化 1/3 - 解锁 BL 锁（讯飞 C8hPro）
echo.
echo ============================================================
if "%RC%"=="0" (
    echo   解锁完成，平板正在重启。
    echo   若没有自动重启，请手动开机。
) else (
    echo   程序返回码：%RC%
    echo   若提示找不到设备，请依次检查：
    echo     1. 驱动是否已安装（重新运行本脚本即可自动安装）
    echo     2. 是否已进入 BROM 模式（关机 + 按住音量减 + 插线）
    echo     3. USB 线是否支持数据传输（换一根试试）
)
echo.
echo   下一步：运行  2-刷入GSI.bat
echo ============================================================
echo.
pause
exit /b

:ERR_ENV
echo   [错误] 运行环境不完整，找不到 spd_dump.exe。
echo.
echo          期望的文件夹结构：
echo            Auto-flash\
echo              Driver_R4.21.3201\
echo              spd_dump_stable_250131\
echo                SPRD\spd_dump.exe      ^<-- 找不到
echo                SPRD\_file\            ^<-- 所有镜像
echo                刷机自动化脚本\        ^<-- 本脚本所在
echo.
echo          请整体拷贝文件夹，不要单独移动脚本。
echo.
pause
exit /b 1

:ERR_FILES
echo.
echo   [错误] 缺少必要文件，请把它们放入：
echo          %CD%\_file\
echo.
pause
exit /b 1

:INSTALL_DRIVER
set "DRVDIR="
if exist "%~dp0..\..\Driver_R4.21.3201\Driver_R4.21.3201\DriversForWin10\DPInst64.exe" set "DRVDIR=%~dp0..\..\Driver_R4.21.3201\Driver_R4.21.3201\DriversForWin10"
if not defined DRVDIR if exist "%~dp0..\..\Driver_R4.21.3201\DriversForWin10\DPInst64.exe" set "DRVDIR=%~dp0..\..\Driver_R4.21.3201\DriversForWin10"
if not defined DRVDIR for /r "%~dp0..\..\" %%F in (DPInst64.exe) do if not defined DRVDIR set "DRVDIR=%%~dpF"
if not defined DRVDIR goto NODRV
for %%I in ("%DRVDIR%") do set "DRVDIR=%%~fI"

set "DPINST=DPInst64.exe"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" set "DPINST=DPInst32.exe"
if not exist "%DRVDIR%\%DPINST%" set "DPINST=DPInst64.exe"
echo         驱动目录：%DRVDIR%
echo         正在静默安装（约 10 - 30 秒）……
pushd "%DRVDIR%"
"%DPINST%" /S /SE >nul 2>&1
set "DPS=!errorlevel!"
popd
echo         DPInst 返回码：!DPS!
timeout /t 2 /nobreak >nul 2>&1
if exist "%SystemRoot%\System32\drivers\sprdvcom.sys" exit /b 0
if exist "%SystemRoot%\System32\drivers\sprdvmdm.sys" exit /b 0
for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\sprdvcom.inf_*") do exit /b 0
exit /b 1

:NODRV
echo         未找到驱动安装程序 DPInst64.exe，跳过自动安装。
exit /b 1
