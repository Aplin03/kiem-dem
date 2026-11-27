# Server tinh chi phuc vu file trong chinh thu muc nay, cho localhost.
# Chay qua start.cmd, khong chay truc tiep.
param([int]$Port = 8779)
Add-Type -AssemblyName System.Web
$root = $PSScriptRoot
$defaultFile = "index.html"
$mime = @{
    ".html"="text/html; charset=utf-8"; ".js"="text/javascript; charset=utf-8"; ".css"="text/css; charset=utf-8";
    ".json"="application/json; charset=utf-8"; ".ico"="image/x-icon"; ".png"="image/png"; ".jpg"="image/jpeg";
    ".jpeg"="image/jpeg"; ".svg"="image/svg+xml"; ".webmanifest"="application/manifest+json; charset=utf-8";
    ".csv"="text/csv; charset=utf-8"; ".md"="text/plain; charset=utf-8"; ".woff2"="font/woff2"; ".woff"="font/woff"
}

$l = New-Object System.Net.HttpListener
try { $l.Prefixes.Add("http://localhost:$Port/"); $l.Start() }
catch { Write-Host "Khong mo duoc cong $Port. Dong chuong trinh dang dung cong nay roi thu lai."; Read-Host "Enter de thoat"; exit 1 }

$url = "http://localhost:$Port/$defaultFile"
Write-Host "Dang chay. Mo trinh duyet: $url"
Start-Process $url
Write-Host "Giu cua so nay mo trong khi dung app. Dong cua so = tat server."

while ($l.IsListening) {
    $c = $l.GetContext()
    $rel = [System.Web.HttpUtility]::UrlDecode($c.Request.Url.AbsolutePath).TrimStart('/')
    if ($rel -eq '') { $rel = $defaultFile }
    $path = Join-Path $root $rel
    # chi phuc vu file trong thu muc nay
    $full = [IO.Path]::GetFullPath($path)
    if ($full.StartsWith($root + [IO.Path]::DirectorySeparatorChar) -and (Test-Path $full -PathType Leaf)) {
        $ext = [IO.Path]::GetExtension($full).ToLower()
        $c.Response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
        $c.Response.Headers.Add("Cache-Control", "no-cache")
        $bytes = [IO.File]::ReadAllBytes($full)
        $c.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $c.Response.StatusCode = 404
    }
    $c.Response.Close()
}
