$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $taskRoot
$suiteLogs = [ordered]@{
    integration='docs/integration_15.log'
    layout='docs/layout_validation_15.log'
    story='docs/story_regression_15.log'
    revision12='docs/revision12_15.log'
    revision14='docs/revision14_15.log'
    revision15='docs/revision15.log'
}
$suiteResults = [ordered]@{}
$checks = 0
foreach ($entry in $suiteLogs.GetEnumerator()) {
    $output = Get-Content -LiteralPath $entry.Value -Raw
    $summary = [regex]::Match($output, 'KALA \w+: (\d+) checks, (\d+) failures')
    if (-not $summary.Success -or [int]$summary.Groups[2].Value -ne 0 -or $output -match 'SCRIPT ERROR|ERROR:|FAIL:|were leaked at exit|colinear') { throw "Failed suite: $($entry.Value)" }
    $suiteResults[$entry.Key] = @{checks=[int]$summary.Groups[1].Value;failures=0;log=$entry.Value}
    $checks += [int]$summary.Groups[1].Value
}
$roomNames = @('home','schoolyard','neighborhood','school','street','loading','relay','pursuit','production','office','ritual','corridor','daisy','hallucination')
$exits = Get-Content docs/standalone15_exits.json -Raw | ConvertFrom-Json
if ($exits.Count -ne 2 -or @($exits | Where-Object exit_code -ne 0).Count) { throw 'Standalone process failed' }
$standalone = [ordered]@{}
$knownDiagnostics = @()
foreach ($renderer in @('forward','compatibility')) {
    $stdout = Get-Content "docs/exe_${renderer}_15_stdout.log" -Raw
    $stderr = [string](Get-Content "docs/exe_${renderer}_15_stderr.log" -Raw)
    if ($stdout -notmatch 'SMOKE BUILD: 0\.15\.0') { throw "Wrong build: $renderer" }
    foreach ($room in $roomNames) { if (-not $stdout.Contains("SMOKE ROOM OK: $room ")) { throw "Missing $room in $renderer" } }
    if ($renderer -eq 'compatibility') {
        $pattern = 'ERROR: Texture with GL ID of \d+: leaked \d+ bytes\.\r?\n\s+at: ~Utilities \(drivers/gles3/storage/utilities\.cpp:82\)\r?\n'
        $diagnostics = [regex]::Matches($stderr,$pattern)
        if ($diagnostics.Count) {
            $knownDiagnostics += @{renderer=$renderer;stage='engine process shutdown';textures=$diagnostics.Count;log="docs/exe_${renderer}_15_stderr.log";status='Existing Godot Compatibility texture-release diagnostic; all rooms loaded and process exited 0.'}
            $stderr = [regex]::Replace($stderr,$pattern,'')
        }
    }
    if (($stdout + $stderr) -match 'SCRIPT ERROR|ERROR:|were leaked at exit') { throw "Runtime diagnostic: $renderer" }
    $standalone[$renderer] = @{rooms_loaded=14;exit_code=0;stdout="docs/exe_${renderer}_15_stdout.log";stderr="docs/exe_${renderer}_15_stderr.log"}
}
$stream = [IO.File]::OpenRead((Join-Path $taskRoot 'KALA.pck'))
$reader = [IO.BinaryReader]::new($stream)
try {
    if ($reader.ReadUInt32() -ne 0x43504447 -or $reader.ReadUInt32() -ne 4) { throw 'Unexpected package format' }
    $stream.Position = 24; $baseOffset = $reader.ReadUInt64(); $directoryOffset = $reader.ReadUInt64()
    $stream.Position = $directoryOffset; $count = $reader.ReadUInt32()
    $paths = [Collections.Generic.HashSet[string]]::new()
    for ($i=0; $i -lt $count; $i++) {
        $length = $reader.ReadUInt32()
        $resourcePath = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($length)).TrimEnd([char]0)
        [void]$paths.Add($resourcePath)
        $offset = $baseOffset + $reader.ReadUInt64(); $size = $reader.ReadUInt64()
        [void]$reader.ReadBytes(16); [void]$reader.ReadUInt32()
        if ($offset -lt $baseOffset -or $offset + $size -gt $directoryOffset) { throw "Invalid package extent: $resourcePath" }
        if ($resourcePath -match '^(docs|tests|tools|backups|\.release_smoke|\.qa_userdata)/') { throw "Development file in build: $resourcePath" }
    }
} finally { $reader.Dispose(); $stream.Dispose() }
$sourceFiles = @('scripts/systems/relay_rebuild.gd','scripts/systems/memory_chamber.gd','scripts/systems/memory_mascot.gd','scripts/systems/main.gd','scripts/systems/level.gd','scripts/systems/expansion_cinematics.gd','scripts/player/player.gd','assets/materials/memory_crt.gdshader','assets/materials/relay_service_floor.gdshader')
foreach ($source in $sourceFiles) { if (-not $paths.Contains($source) -and -not $paths.Contains($source+'.remap')) { throw "Missing resource: $source" } }
function Describe-File([string]$path) {
    return @{file=$path;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$screenshots = @()
foreach ($renderer in @('forward','compat')) {
    $logPath = "docs/capture15_${renderer}_final.log"
    $output = Get-Content -LiteralPath $logPath -Raw
    if ($output -match 'SCRIPT ERROR|ERROR:') { throw "Render failed: $renderer" }
    foreach ($name in @('relay','relay_blue','socket','r17_unit','lever','generator','generator_blue','contact','archive','stairs','memory','memory_console','memory_signal','memory_mascot','service')) {
        if (-not $output.Contains("CAPTURE15 $name 0")) { throw "Missing render: $renderer / $name" }
        $suffix = '_15.png'; if ($renderer -eq 'compat') { $suffix = '_15_compat.png' }
        $screenshots += Describe-File "docs/screenshots/$name$suffix"
    }
}
$report = [ordered]@{
    version='0.15.0';verified_utc=[DateTime]::UtcNow.ToString('o');checks=$checks;failures=0
    suites=$suiteResults;standalone=$standalone;packed_files=$count;known_diagnostics=$knownDiagnostics
    files=@(@('KALA.exe','KALA.pck','THIRD_PARTY_NOTICES.txt') | ForEach-Object { Describe-File $_ })
    source_files=@($sourceFiles | ForEach-Object { Describe-File $_ });screenshots=$screenshots
    limitations=@('Automated gameplay, physical routes, the B1 exit cinematic and engine renders were checked; a manual playthrough to every ending was not performed.')
}
$report | ConvertTo-Json -Depth 8 | Set-Content docs/validation_15.json
Write-Output "KALA 0.15: $checks checks, 0 failures; 14 standalone rooms in both renderers; $count packed files; $($screenshots.Count) verified screenshots."
