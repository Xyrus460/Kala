$ErrorActionPreference='Stop'
$text=[IO.File]::ReadAllText("$PSScriptRoot\..\docs\reference_script_1.txt")
function Decode-KalaString([string]$v) { return $v.Replace('\\n',"`n").Replace('\n',"`n").Replace("\'", "'").Replace('\"','"') }
$notes=@{}
$q="'((?:\\.|[^'\\])*)'"
foreach($line in $text.Split("`n")) {
    if($line -match '^\s*(noteObject|archiveNote)\(') {
        $strings=[regex]::Matches($line,$q)
        $offset=if($line -match '^\s*noteObject') {1} else {0}
        if($strings.Count -ge ($offset+3)) {
            $title=Decode-KalaString $strings[$offset].Groups[1].Value
            $body=Decode-KalaString $strings[$offset+1].Groups[1].Value
            $id=$strings[$offset+2].Groups[1].Value
            $notes[$id]=@{title=$title;body=$body}
        }
    }
}
$block=[regex]::Match($text,'(?s)const evidenceContent=\{(.*?)\n\};').Groups[1].Value
$evidence=@{}
foreach($m in [regex]::Matches($block,"(\w+):\[$q,$q\]")) {
    $evidence[$m.Groups[1].Value]=@{title=(Decode-KalaString $m.Groups[2].Value);body=(Decode-KalaString $m.Groups[3].Value)}
}
$dialogues=@{}
$block=[regex]::Match($text,'(?s)function schoolDialogueLines\(after\).*?return \{(.*?)\};\}').Groups[1].Value
foreach($name in @('Sari','Adit','Raka','Danu')) {
    $line=($block.Split("`n") | Where-Object {$_ -match "^\s*$name"})
    $s=[regex]::Matches($line,$q)
    $dialogues[$name]=@{before=(Decode-KalaString $s[$s.Count-1].Groups[1].Value);after=(Decode-KalaString $s[1].Groups[1].Value)}
    if($name -eq 'Sari' -or $name -eq 'Adit') { $dialogues[$name].before=$dialogues[$name].after }
}
@{notes=$notes;evidence=$evidence;dialogues=$dialogues} | ConvertTo-Json -Depth 8 | Set-Content "$PSScriptRoot\..\assets\story.json" -Encoding UTF8
Write-Output "Extracted $($notes.Count) notes, $($evidence.Count) evidence, $($dialogues.Count) dialogues."
