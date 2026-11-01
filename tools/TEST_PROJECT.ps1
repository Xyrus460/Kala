$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskEngine = Join-Path $PSScriptRoot 'engine\stable\Godot_v4.7.2-stable_win64_console.exe'
# Keep test logs/settings separate from the player's roaming profile.
$env:APPDATA = Join-Path $taskRoot '.qa_userdata'
function Invoke-KalaCheck([string[]]$Arguments, [string]$Transcript) {
    # Capture native stderr as well: engine destructor diagnostics can appear
    # after --log-file has closed, so that file alone is not a complete check.
    $ErrorActionPreference = 'Continue'
    # Retain resource identities in diagnostics if the engine reports shutdown leaks.
    & $taskEngine --verbose @Arguments 2>&1 | Tee-Object -FilePath $Transcript
    $script:taskExitCode = $LASTEXITCODE
    $taskOutput = Get-Content -LiteralPath $Transcript -Raw
    if ($taskOutput -match 'SCRIPT ERROR|ERROR:|FAIL:|were leaked at exit') { $script:taskExitCode = 1 }
}
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--editor','--import','--quit','--log-file',"$taskRoot\docs\import_latest.log") -Transcript "$taskRoot\docs\import_latest_console.log"
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/integration.tscn','--log-file',"$taskRoot\docs\integration_latest.log") -Transcript "$taskRoot\docs\integration_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\integration_latest_console.log" -Raw) -notmatch 'KALA INTEGRATION: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/layout_validation.tscn','--log-file',"$taskRoot\docs\layout_latest.log") -Transcript "$taskRoot\docs\layout_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\layout_latest_console.log" -Raw) -notmatch 'KALA LAYOUT: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/story_regression.tscn','--log-file',"$taskRoot\docs\story_latest.log") -Transcript "$taskRoot\docs\story_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\story_latest_console.log" -Raw) -notmatch 'KALA STORY: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/claw_combat.tscn','--log-file',"$taskRoot\docs\claw_latest.log") -Transcript "$taskRoot\docs\claw_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\claw_latest_console.log" -Raw) -notmatch '6 checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision04.tscn','--log-file',"$taskRoot\docs\revision04_latest.log") -Transcript "$taskRoot\docs\revision04_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision04_latest_console.log" -Raw) -notmatch 'KALA REVISION04: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision05.tscn','--log-file',"$taskRoot\docs\revision05_latest.log") -Transcript "$taskRoot\docs\revision05_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision05_latest_console.log" -Raw) -notmatch 'KALA REVISION05: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision06.tscn','--log-file',"$taskRoot\docs\revision06_latest.log") -Transcript "$taskRoot\docs\revision06_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision06_latest_console.log" -Raw) -notmatch 'KALA REVISION06: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision07.tscn','--log-file',"$taskRoot\docs\revision07_latest.log") -Transcript "$taskRoot\docs\revision07_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision07_latest_console.log" -Raw) -notmatch 'KALA REVISION07: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision08.tscn','--log-file',"$taskRoot\docs\revision08_latest.log") -Transcript "$taskRoot\docs\revision08_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision08_latest_console.log" -Raw) -notmatch 'KALA REVISION08: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision09.tscn','--log-file',"$taskRoot\docs\revision09_latest.log") -Transcript "$taskRoot\docs\revision09_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision09_latest_console.log" -Raw) -notmatch 'KALA REVISION09: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision10.tscn','--log-file',"$taskRoot\docs\revision10_latest.log") -Transcript "$taskRoot\docs\revision10_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision10_latest_console.log" -Raw) -notmatch 'KALA REVISION10: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision11.tscn','--log-file',"$taskRoot\docs\revision11_latest.log") -Transcript "$taskRoot\docs\revision11_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision11_latest_console.log" -Raw) -notmatch 'KALA REVISION11: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision12.tscn','--log-file',"$taskRoot\docs\revision12_latest.log") -Transcript "$taskRoot\docs\revision12_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision12_latest_console.log" -Raw) -notmatch 'KALA REVISION12: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision13.tscn','--log-file',"$taskRoot\docs\revision13_latest.log") -Transcript "$taskRoot\docs\revision13_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision13_latest_console.log" -Raw) -notmatch 'KALA REVISION13: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision14.tscn','--log-file',"$taskRoot\docs\revision14_latest.log") -Transcript "$taskRoot\docs\revision14_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision14_latest_console.log" -Raw) -notmatch 'KALA REVISION14: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision15.tscn','--log-file',"$taskRoot\docs\revision15_latest.log") -Transcript "$taskRoot\docs\revision15_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision15_latest_console.log" -Raw) -notmatch 'KALA REVISION15: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision16.tscn','--log-file',"$taskRoot\docs\revision16_latest.log") -Transcript "$taskRoot\docs\revision16_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision16_latest_console.log" -Raw) -notmatch 'KALA REVISION16: \d+ checks, 0 failures') { $taskExitCode = 1 }
if ($taskExitCode -ne 0) { exit $taskExitCode }
Invoke-KalaCheck -Arguments @('--headless','--audio-driver','Dummy','--path',$taskRoot,'--scene','res://tests/revision17.tscn','--log-file',"$taskRoot\docs\revision17_latest.log") -Transcript "$taskRoot\docs\revision17_latest_console.log"
if ((Get-Content -LiteralPath "$taskRoot\docs\revision17_latest_console.log" -Raw) -notmatch 'KALA REVISION17: \d+ checks, 0 failures') { $taskExitCode = 1 }
exit $taskExitCode
