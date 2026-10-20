# Script PowerShell untuk Web Server Lokal WebGIS
$ErrorActionPreference = "Stop"

$port = 8000
$started = $false
$listener = $null

while (-not $started -and $port -le 8010) {
    try {
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://127.0.0.1:$port/")
        $listener.Start()
        $started = $true
    } catch {
        $port++
    }
}

if (-not $started) {
    Write-Host "Gagal membuka port antara 8000 - 8010." -ForegroundColor Red
    exit 1
}

$url = "http://127.0.0.1:$port/index.html"
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  WebGIS Kabupaten Flores Timur Berhasil Dijalankan!  " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "URL Server : http://127.0.0.1:$port/" -ForegroundColor Yellow
Write-Host "Membuka browser otomatis..." -ForegroundColor Gray
Write-Host "Tekan Ctrl + C pada jendela ini untuk menghentikan server." -ForegroundColor DarkGray
Write-Host "------------------------------------------------------" -ForegroundColor Cyan

Start-Process $url

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($path)) {
            $path = "index.html"
        }
        $path = [System.Uri]::UnescapeDataString($path).Replace('/', '\')
        $filePath = Join-Path $root $path

        if (Test-Path $filePath -PathType Leaf) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $contentType = switch ($ext) {
                    ".html"    { "text/html; charset=utf-8" }
                    ".css"     { "text/css; charset=utf-8" }
                    ".js"      { "application/javascript; charset=utf-8" }
                    ".json"    { "application/json; charset=utf-8" }
                    ".geojson" { "application/geo+json; charset=utf-8" }
                    ".png"     { "image/png" }
                    ".jpg"     { "image/jpeg" }
                    ".jpeg"    { "image/jpeg" }
                    ".gif"     { "image/gif" }
                    ".svg"     { "image/svg+xml" }
                    ".ico"     { "image/x-icon" }
                    default    { "application/octet-stream" }
                }
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                $response.AddHeader("Access-Control-Allow-Origin", "*")
                $response.AddHeader("Cache-Control", "no-cache")
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } catch {
                $response.StatusCode = 500
            }
        } else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found")
            $response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $response.OutputStream.Close()
    }
} finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
}
