@echo off
cd /d "%~dp0"
start "KALA Compatibility" "KALA.exe" --rendering-method gl_compatibility --rendering-driver opengl3
