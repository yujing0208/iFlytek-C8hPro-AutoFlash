@echo off
chcp 936 >nul
setlocal EnableDelayedExpansion
title 刷机自动化 2/3 - 刷入 GSI

echo ============================================================
echo   刷机自动化   步骤 2 / 3
echo   刷入 GSI（第三方系统镜像）
echo ============================================================
echo.
echo   【前提】
echo     已完成步骤 1，设备 bootloader 处于解锁状态。
echo     若尚未解锁，请先运行  1-解锁BL.bat
echo.
echo   【本步骤会做什么】
echo     把 _file\system.img 写入 system 分区，并清空 userdata。
echo     system.img 约 3 GB，预计耗时 1 - 3 分钟。
echo.
echo ============================================================
echo.

rem ===== 可选提速：默认关闭。流程跑通后，改成 blk_size 65535 可加快写入 =====
set "BLK="

cd /d "%~dp0..\SPRD" 2>nul
if not exist "spd_dump.exe" goto ERR_ENV

echo   [1/3] 检查展锐驱动……
if exist "%SystemRoot%\System32\drivers\sprdvcom.sys" (
    echo         已检测到驱动。
) else (
    echo         [提示] 未检测到展锐驱动。若连接不上设备，
    echo                请先运行  1-解锁BL.bat  自动安装驱动。
)
echo.

echo   [2/3] 检查所需文件……
set "MISS="
for %%F in (fdl1.bin fdl2.bin system.img) do (
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
echo   正在写入 system.img，请勿拔线……
echo.
spd_dump --wait 300 fdl _file\fdl1.bin 0x5500 fdl _file\fdl2.bin 0x9efffe00 exec %BLK% w system _file\system.img e userdata reset
set "RC=%errorlevel%"
title 刷机自动化 2/3 - 刷入 GSI
echo.
echo ============================================================
if "%RC%"=="0" (
    echo   刷入完成，平板正在重启。
    echo   首次开机可能需要几分钟，请耐心等待。
) else (
    echo   程序返回码：%RC%
    echo   请依次检查：
    echo     1. 驱动是否已安装（运行 1-解锁BL.bat 可自动安装）
    echo     2. 是否已进入 BROM 模式（关机 + 按住音量减 + 插线）
    echo     3. USB 线是否支持数据传输
)
echo.
echo   如需回锁并恢复原系统，请运行  3-回锁恢复.bat
echo ============================================================
echo.
pause
exit /b

:ERR_ENV
echo   [错误] 运行环境不完整，找不到 spd_dump.exe。
echo.
echo          期望的文件夹结构：
echo            Auto-flash\
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
