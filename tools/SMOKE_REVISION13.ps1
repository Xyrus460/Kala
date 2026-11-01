$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$smokeRoot=Join-Path $taskRoot '.release_smoke\revision13'
New-Item -ItemType Directory -Force -Path $smokeRoot | Out-Null
foreach ($file in @('KALA.exe','KALA.pck','THIRD_PARTY_NOTICES.txt')) {
    Copy-Item -LiteralPath (Join-Path $taskRoot $file) -Destination $smokeRoot
}
$env:APPDATA=Join-Path $taskRoot '.qa_userdata'
$results=@()
foreach ($renderer in @('forward','compatibility')) {
    $arguments=@('--audio-driver','Dummy','--path',$smokeRoot,'--resolution','960x540')
    if ($renderer -eq 'compatibility') { $arguments+=@('--rendering-method','gl_compatibility') }
    $arguments+=@('--','--smoke')
    $stdout=Join-Path $taskRoot "docs\exe_${renderer}_13_stdout.log"
    $stderr=Join-Path $taskRoot "docs\exe_${renderer}_13_stderr.log"
    $process=Start-Process -FilePath (Join-Path $smokeRoot 'KALA.exe') -ArgumentList $arguments -WorkingDirectory $smokeRoot -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    Write-Output "SMOKE13 START $renderer PID $($process.Id)"
    $deadline=[DateTime]::UtcNow.AddMinutes(4)
    while (-not $process.WaitForExit(10000)) {
        if ([DateTime]::UtcNow -gt $deadline) { $process.Kill();throw "Smoke timed out: $renderer" }
    }
    $process.Refresh()
    $exitCode=$process.ExitCode
    $results+=@{renderer=$renderer;exit_code=$exitCode;stdout=$stdout;stderr=$stderr}
    $results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $taskRoot 'docs\standalone13_exits.json')
    Write-Output "SMOKE13 EXIT $renderer $exitCode"
    if ($exitCode -ne 0) { exit 1 }
}
