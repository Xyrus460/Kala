$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskEngine = Join-Path $PSScriptRoot 'engine\stable\Godot_v4.7.2-stable_win64_console.exe'
$taskMovie = Join-Path $taskRoot 'tools\authoring\audit_native17.ogv'
New-Item -ItemType Directory -Force -Path (Split-Path $taskMovie -Parent) | Out-Null
$taskArguments = @('--path', ('"' + $taskRoot + '"'), '--scene', 'res://tools/audit_film17.tscn', '--rendering-method', 'gl_compatibility', '--write-movie', ('"' + $taskMovie + '"'), '--fixed-fps', '24', '--disable-vsync')
$taskProcess = Start-Process -FilePath $taskEngine -ArgumentList $taskArguments -WorkingDirectory $taskRoot -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $taskRoot 'docs\film17_render_stdout.log') -RedirectStandardError (Join-Path $taskRoot 'docs\film17_render_stderr.log')
if ($taskProcess.ExitCode -ne 0) { exit $taskProcess.ExitCode }
$taskFfmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($taskFfmpeg) {
    # Decode validation only. Render directly to OGV using Godot's writer:
    # the locally installed FFmpeg/libtheora encoder produces corrupt blocks.
    & $taskFfmpeg.Source -hide_banner -v error -xerror -i $taskMovie -f null -
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Copy-Item -LiteralPath $taskMovie -Destination (Join-Path $taskRoot 'assets\video\audit_17_maret.ogv')
Get-FileHash -LiteralPath (Join-Path $taskRoot 'assets\video\audit_17_maret.ogv') -Algorithm SHA256
