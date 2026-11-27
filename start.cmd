@echo off
rem Double-click file nay de mo App kiem dem cay NTBP tren may tinh.
rem No chay mot server nho tren may ban (localhost) va mo trinh duyet.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
