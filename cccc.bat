@echo off
echo 正在清除 Claude 歷史記錄...

powershell -NoProfile -Command "Clear-Content 'C:\Users\user\.claude\history.jsonl'; Get-Item 'C:\Users\user\.claude\history.jsonl' | Select-Object Name, Length"

echo 完成！
cmd /k