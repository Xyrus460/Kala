param([string]$Source = 'C:\Users\alama\Downloads\Kala_Chapter_1_Tiga_Fase (6).html')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$html = [IO.File]::ReadAllText($Source)
$dirs = @('textures','audio','fonts','reference')
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path "$root\assets\$d" | Out-Null }
$matches = [regex]::Matches($html, 'data:([^;\s"'']+);base64,([A-Za-z0-9+/=]+)')
$manifest = @()
$hashes = @{}
foreach ($m in $matches) {
    $mime = $m.Groups[1].Value
    $bytes = [Convert]::FromBase64String($m.Groups[2].Value)
    $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
    $context = $html.Substring([Math]::Max(0,$m.Index-140),[Math]::Min(140,$m.Index))
    if ($hashes.ContainsKey($hash)) { $path = $hashes[$hash] } else {
        $ext = switch ($mime) { 'image/png' {'png'} 'image/jpeg' {'jpg'} 'image/webp' {'webp'} 'audio/mpeg' {'mp3'} 'audio/mp3' {'mp3'} 'audio/wav' {'wav'} 'audio/ogg' {'ogg'} 'font/ttf' {'ttf'} 'video/webm' {'webm'} default {'bin'} }
        $dir = if ($mime.StartsWith('image')) {'textures'} elseif ($mime.StartsWith('audio')) {'audio'} elseif ($mime.StartsWith('font')) {'fonts'} else {'reference'}
        if ($bytes.Length -gt 8 -and [Text.Encoding]::ASCII.GetString($bytes,4,4) -eq 'ftyp') { $ext='mp4'; $dir='reference/audio_original'; New-Item -ItemType Directory -Force -Path "$root\assets\$dir" | Out-Null }
        $path = 'assets/' + $dir + '/embedded_' + ('{0:d3}' -f $manifest.Count) + '.' + $ext
        [IO.File]::WriteAllBytes((Join-Path $root $path),$bytes)
        $hashes[$hash] = $path
    }
    $manifest += [ordered]@{ index=$manifest.Count; mime=$mime; path=$path; bytes=$bytes.Length; sha256=$hash; context=$context }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$root\docs\asset_manifest.json" -Encoding UTF8
Get-FileHash -LiteralPath $Source -Algorithm SHA256 | Format-List | Out-String | Set-Content "$root\docs\reference_sha256.txt"
$manifest | ForEach-Object { '{0:000}  {1}  {2} bytes  {3}' -f $_.index,$_.path,$_.bytes,$_.sha256 } | Set-Content "$root\docs\asset_inventory.txt" -Encoding UTF8
Write-Output "Extracted $($manifest.Count) references, $($hashes.Count) unique assets."
