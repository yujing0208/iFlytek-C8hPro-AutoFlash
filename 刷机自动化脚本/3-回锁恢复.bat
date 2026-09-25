@echo off
chcp 936 >nul
setlocal EnableDelayedExpansion
title 刷机自动化 3/3 - 回锁并恢复原系统

echo ============================================================
echo   刷机自动化   步骤 3 / 3
echo   回锁 Bootloader 并恢复原厂系统
echo ============================================================
echo.
echo   【危险操作，请先确认】
echo     本步骤会把 bootloader 重新上锁，并写回原厂镜像。
echo     如果 _file 里的镜像不是本机原厂备份，
echo     设备可能无法开机！
echo.
echo   【本步骤会写入】
echo     uboot.bin、splloader.bin           原厂引导，用于回锁
echo     boot.bin、system.bin、vendor.bin
echo     vbmeta.bin、misc.bin、miscdata.bin
echo     并清空 userdata
echo.
echo   【预计耗时】
echo     约 3 - 6 分钟（system.bin 3 GB + vendor.bin 550 MB）
echo.
echo ============================================================
echo.
set "ANS="
set /p "ANS=  确认回锁恢复请输入 Y 并回车（其他任意键取消）: "
if /i not "%ANS%"=="Y" goto ABORT
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
for %%F in (uboot.bin splloader.bin boot.bin system.bin vendor.bin vbmeta.bin fdl1.bin fdl2.bin) do (
    if exist "_file\%%F" (
        echo         [OK]   %%F
    ) else (
        echo         [缺少] %%F
        set "MISS=1"
    )
)
if defined MISS goto ERR_FILES

set "MISC_CMD="
if exist "_file\misc.bin" set "MISC_CMD=w misc _file\misc.bin"
set "MISCDATA_CMD="
if exist "_file\miscdata.bin" set "MISCDATA_CMD=w miscdata _file\miscdata.bin"
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
echo   正在回写原厂镜像并重新上锁，请勿拔线……
echo.
spd_dump --wait 300 fdl _file\fdl1.bin 0x5500 fdl _file\fdl2.bin 0x9efffe00 exec %BLK% w uboot _file\uboot.bin w splloader _file\splloader.bin w boot _file\boot.bin w system _file\system.bin w vendor _file\vendor.bin w vbmeta _file\vbmeta.bin %MISC_CMD% %MISCDATA_CMD% e userdata reset
set "RC=%errorlevel%"
title 刷机自动化 3/3 - 回锁并恢复原系统
echo.
echo ============================================================
if "%RC%"=="0" (
    echo   回锁恢复完成，平板正在重启。
    echo   开机后解锁提示应该消失，即已恢复原厂锁定状态。
) else (
    echo   程序返回码：%RC%
    echo   请依次检查：
    echo     1. 驱动是否已安装（运行 1-解锁BL.bat 可自动安装）
    echo     2. 是否已进入 BROM 模式（关机 + 按住音量减 + 插线）
    echo     3. USB 线是否支持数据传输
)
echo ============================================================
echo.
pause
exit /b

:ABORT
echo.
echo   已取消，未做任何写入。
echo.
pause
exit /b 0

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
echo   [错误] 缺少必要文件，回锁恢复无法继续。
echo          请把它们放入：%CD%\_file\
echo.
pause
exit /b 1
