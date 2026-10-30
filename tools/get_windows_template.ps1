$ErrorActionPreference = 'Stop'
$taskUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
$taskTarget = Join-Path $PSScriptRoot 'engine\stable\windows_release_x86_64.exe'
function Get-ZipRange([long]$From, [long]$To) {
    $request = [Net.HttpWebRequest]::Create($taskUrl)
    $request.UserAgent = 'KALA Native Migration'
    if ($From -lt 0) { $request.AddRange($From) } else { $request.AddRange($From, $To) }
    $response = $request.GetResponse()
    if ([int]$response.StatusCode -ne 206) { $response.Dispose(); throw 'Server did not honor ZIP byte range.' }
    $memory = [IO.MemoryStream]::new()
    $response.GetResponseStream().CopyTo($memory)
    $response.Dispose()
    return ,$memory.ToArray()
}
$tail = Get-ZipRange -From -65536 -To 0
$end = -1
for ($i = $tail.Length - 22; $i -ge 0; $i--) { if ([BitConverter]::ToUInt32($tail,$i) -eq 0x06054b50) { $end=$i; break } }
if ($end -lt 0) { throw 'ZIP central directory not found.' }
$size = [BitConverter]::ToUInt32($tail,$end+12)
$offset = [BitConverter]::ToUInt32($tail,$end+16)
$directory = Get-ZipRange -From $offset -To ($offset+$size-1)
for ($i=0; $i -lt $directory.Length;) {
    if ([BitConverter]::ToUInt32($directory,$i) -ne 0x02014b50) { throw 'Invalid ZIP directory.' }
    $compressed = [BitConverter]::ToUInt32($directory,$i+20)
    $nameLength = [BitConverter]::ToUInt16($directory,$i+28)
    $extraLength = [BitConverter]::ToUInt16($directory,$i+30)
    $commentLength = [BitConverter]::ToUInt16($directory,$i+32)
    $localOffset = [BitConverter]::ToUInt32($directory,$i+42)
    $name = [Text.Encoding]::UTF8.GetString($directory,$i+46,$nameLength)
    if ($name.EndsWith('/windows_release_x86_64.exe')) {
        $header = Get-ZipRange -From $localOffset -To ($localOffset+29)
        $payload = $localOffset+30+[BitConverter]::ToUInt16($header,26)+[BitConverter]::ToUInt16($header,28)
        $bytes = Get-ZipRange -From $payload -To ($payload+$compressed-1)
        $inputStream = [IO.MemoryStream]::new($bytes,$false)
        $inflate = [IO.Compression.DeflateStream]::new($inputStream,[IO.Compression.CompressionMode]::Decompress)
        $output = [IO.File]::Create($taskTarget)
        $inflate.CopyTo($output)
        $output.Dispose(); $inflate.Dispose(); $inputStream.Dispose()
        Get-FileHash -LiteralPath $taskTarget -Algorithm SHA256
        exit 0
    }
    $i += 46+$nameLength+$extraLength+$commentLength
}
throw 'Windows release template not present in official archive.'
