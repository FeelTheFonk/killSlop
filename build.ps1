$p = (Get-Content ".\src\p.ps1" -Raw) -replace '(?m)^\s+', '' -replace '\r?\n|\r', ' '

$m = [IO.MemoryStream]::new()
$d = [IO.Compression.DeflateStream]::new($m, [IO.Compression.CompressionLevel]::Optimal)
$s = [IO.StreamWriter]::new($d, [Text.Encoding]::UTF8)
$s.Write($p)
$s.Close()

$b = [Convert]::ToBase64String($m.ToArray())

$iPath = ".\i.ps1"
$iContent = Get-Content $iPath -Raw
$iContent = $iContent -replace '\$b=''.*?''', "`$b='$b'"
[IO.File]::WriteAllText("$PWD\i.ps1", $iContent, [Text.Encoding]::UTF8)

Write-Host "[BUILD] Payload compilé et injecté dans i.ps1 avec succès."
