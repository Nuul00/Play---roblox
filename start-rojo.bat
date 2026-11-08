@echo off
cd /d "%~dp0"
set PATH=%PATH%;%USERPROFILE%\.rokit\bin;%USERPROFILE%\.aftman\bin
rojo serve
pause
