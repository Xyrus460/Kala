$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskEngine = Join-Path $PSScriptRoot 'engine\stable\Godot_v4.7.2-stable_win64_console.exe'
& $taskEngine --headless --audio-driver Dummy --path $taskRoot --script res://tools/bake_levels.gd --log-file "$taskRoot\docs\bake_levels.log"
exit $LASTEXITCODE
