@echo off
if exist "%~dp0KALA.exe" (
  "%~dp0KALA.exe"
) else (
  "%~dp0tools\engine\stable\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
)
