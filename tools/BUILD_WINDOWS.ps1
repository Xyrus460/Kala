$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskEngine=Join-Path $PSScriptRoot 'engine\stable\Godot_v4.7.2-stable_win64_console.exe'
& $taskEngine --headless --audio-driver Dummy --path $taskRoot --export-release 'Windows Desktop' "$taskRoot\KALA.exe" --log-file "$taskRoot\docs\export_windows.log"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Get-FileHash -LiteralPath "$taskRoot\KALA.exe" -Algorithm SHA256
