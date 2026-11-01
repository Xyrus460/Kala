$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskSmokeRoot = Join-Path $taskRoot '.release_smoke\revision17'
New-Item -ItemType Directory -Force -Path $taskSmokeRoot | Out-Null
foreach ($taskFile in @('KALA.exe','KALA.pck','THIRD_PARTY_NOTICES.txt')) {
    Copy-Item -LiteralPath (Join-Path $taskRoot $taskFile) -Destination $taskSmokeRoot
}
$env:APPDATA = Join-Path $taskRoot '.qa_userdata\smoke16'
$taskResults = @()
foreach ($taskRenderer in @('forward','compatibility')) {
    $taskArguments = @('--audio-driver','Dummy','--path',$taskSmokeRoot,'--resolution','960x540')
    if ($taskRenderer -eq 'compatibility') { $taskArguments += @('--rendering-method','gl_compatibility') }
    $taskArguments += @('--','--smoke')
    $taskStdout = Join-Path $taskRoot "docs\exe_${taskRenderer}_17_stdout.log"
    $taskStderr = Join-Path $taskRoot "docs\exe_${taskRenderer}_17_stderr.log"
    $taskProcess = Start-Process -FilePath (Join-Path $taskSmokeRoot 'KALA.exe') -ArgumentList $taskArguments -WorkingDirectory $taskSmokeRoot -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
    Write-Output "SMOKE17 START $taskRenderer PID $($taskProcess.Id)"
    $taskDeadline = [DateTime]::UtcNow.AddMinutes(5)
    while (-not $taskProcess.WaitForExit(10000)) {
        if ([DateTime]::UtcNow -gt $taskDeadline) { $taskProcess.Kill(); throw "Smoke timed out: $taskRenderer" }
    }
    $taskProcess.Refresh()
    $taskResults += @{renderer=$taskRenderer;exit_code=$taskProcess.ExitCode;stdout=$taskStdout;stderr=$taskStderr}
    $taskResults | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $taskRoot 'docs\standalone17_exits.json')
    Write-Output "SMOKE17 EXIT $taskRenderer $($taskProcess.ExitCode)"
    if ($taskProcess.ExitCode -ne 0) { exit 1 }
    $taskOutput = (Get-Content -LiteralPath $taskStdout -Raw) + (Get-Content -LiteralPath $taskStderr -Raw)
    if ($taskOutput -match 'SCRIPT ERROR|FAIL:|SMOKE17:') { throw "Smoke diagnostics: $taskRenderer" }
    if (([regex]::Matches($taskOutput,'SMOKE FEATURE OK:')).Count -ne 3) { throw "Feature smoke coverage incomplete: $taskRenderer" }
    if (([regex]::Matches($taskOutput,'SMOKE ROOM OK:')).Count -ne 14 -or ([regex]::Matches($taskOutput,'SMOKE MENU OK:')).Count -ne 2) { throw "Smoke coverage incomplete: $taskRenderer" }
}
exit 0
