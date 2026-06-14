@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 1. 設定目標資料夾路徑 (維持你堅持的絕對路徑)
set "TARGET_DIR=D:\Cthis"

:: ============================================================
:: 排除清單 (PROTECT)：路徑中只要含以下任一片段，該 .exe 就「不刪」
::   \.venv\        -> Python 虛擬環境的直譯器 (上次就是被這支誤殺)
::   \target\       -> Rust / cargo 編譯產物 (RRust)
::   \.git\         -> git 內部物件
::   \node_modules\ -> 前端依賴 (預防)
:: 預覽階段與刪除階段共用同一份規則，確保「看到的 == 刪掉的」
:: 若要增減，預覽的 findstr 與迴圈的 findstr 兩處都要一起改
:: ============================================================

:: 2. 存在性檢查邏輯
if not exist "%TARGET_DIR%" (
    echo [錯誤] 找不到資料夾: %TARGET_DIR%
    pause
    exit /b
)

echo ========================================
echo [第一階段：預覽] 以下檔案即將被刪除 (已套用排除清單)：
echo ----------------------------------------
:: 列出所有 .exe，再用 findstr /v 濾掉受保護路徑
dir /s /b /a-d "%TARGET_DIR%\*.exe" | findstr /i /v /c:"\.venv\\" /c:"\target\\" /c:"\.git\\" /c:"\node_modules\\"
echo ----------------------------------------

echo [第二階段：緩衝] 請檢查清單是否正確。
echo 如果發現不該刪的檔案，請直接 "關閉視窗" 或 "按 Ctrl+C"。
echo 倒數 6秒後將啟動不可逆刪除...
echo ========================================

:: 3. 等待 6 秒 (timeout 在 stdin 被重導向時會瞬間失敗，
::    故用 || 退回 ping 計時，ping 不讀 stdin，任何啟動方式都能穩定撐 6 秒)
timeout /t 6 /nobreak || ping -n 7 127.0.0.1 >nul


echo ========================================

:: 4. 核心邏輯：逐檔判斷，受保護路徑跳過，其餘才刪
set /a count=0
set /a skipped=0
for /r "%TARGET_DIR%" %%f in (*.exe) do (
    rem findstr 命中任一排除片段 -> errorlevel 0 -> 略過；找不到 -> errorlevel 1 -> 刪除
    echo "%%f" | findstr /i /c:"\.venv\\" /c:"\target\\" /c:"\.git\\" /c:"\node_modules\\" >nul
    if errorlevel 1 (
        echo [清理中] %%f
        del /f /q "%%f"
        set /a count+=1
    ) else (
        echo [略過-保護] %%f
        set /a skipped+=1
    )
)

:: 5. 執行結果彙報
echo ----------------------------------------
if %count% equ 0 (
    echo [通知] 沒有發現任何需要清理的 .exe 檔案。
) else (
    echo [完成] 總計已從 %TARGET_DIR% 移除 %count% 個執行檔。
)
echo [保護] 略過受保護路徑檔案數: %skipped%
echo ========================================

:: 結尾停住，讓你看完彙報 (pause 失效時用 ping 再撐 8 秒保底)
pause || ping -n 9 127.0.0.1 >nul
