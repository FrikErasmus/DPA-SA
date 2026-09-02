$ErrorActionPreference = "Stop"

$ngrok = "C:\Users\frike\AppData\Local\Microsoft\WinGet\Packages\Ngrok.Ngrok_Microsoft.Winget.Source_8wekyb3d8bbwe\ngrok.exe"
if (-not (Test-Path $ngrok)) {
    $ngrok = (Get-Command ngrok -ErrorAction SilentlyContinue).Source
}
if (-not $ngrok) {
    throw "ngrok not found. Install with: winget install ngrok.ngrok"
}

if (-not $env:NGROK_AUTHTOKEN) {
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*NGROK_AUTHTOKEN\s*=\s*(.+)\s*$') {
                $env:NGROK_AUTHTOKEN = $Matches[1].Trim()
            }
        }
    }
}

if (-not $env:NGROK_AUTHTOKEN -or $env:NGROK_AUTHTOKEN -eq "your_token_here") {
    Write-Host "Add your ngrok authtoken first:"
    Write-Host "1. Sign up at https://dashboard.ngrok.com/signup"
    Write-Host "2. Copy token from https://dashboard.ngrok.com/get-started/your-authtoken"
    Write-Host "3. Save it in .env as NGROK_AUTHTOKEN=..."
    exit 1
}

& $ngrok config add-authtoken $env:NGROK_AUTHTOKEN | Out-Null

Write-Host "Starting ngrok on http://localhost:8080 ..."
Start-Process -FilePath $ngrok -ArgumentList "http","8080" -WindowStyle Normal

Start-Sleep -Seconds 3
try {
    $tunnels = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -TimeoutSec 5
    $publicUrl = ($tunnels.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1).public_url
    if ($publicUrl) {
        Write-Host ""
        Write-Host "Share this URL:" -ForegroundColor Green
        Write-Host $publicUrl
    }
} catch {
    Write-Host "Tunnel started. Open http://127.0.0.1:4040 for the public URL."
}
