$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runtime = Join-Path $workspace '.dart_tool'
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
$lock = [IO.File]::Open((Join-Path $runtime 'shared-backend-start.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
function Get-BackendHealth {
    try {
        return Invoke-RestMethod -Uri 'http://127.0.0.1:8788/healthz' -TimeoutSec 3
    } catch { return $null }
}
function Confirm-Backend($health) {
    if ($health.mode -ne 'real-firebase-localhost' -or $health.projectId -ne 'accesstransit-b615b') {
        throw 'Port 8788 belongs to another service. No process was stopped.'
    }
    if (-not $health.ready) {
        throw ('Backend is running but not ready: ' + ($health.reasons -join ', ') + '. Check the backend logs and Firebase CLI sign-in.')
    }
}
try {
    $health = Get-BackendHealth
    if ($null -ne $health) {
        Confirm-Backend $health
        Write-Output 'AccessTransit localhost backend is ready (existing process).'
        exit 0
    }
    $node = (Get-Command node -ErrorAction Stop).Source
    $entry = Join-Path $PSScriptRoot 'serve-shared-backend.mjs'
    $process = Start-Process -FilePath $node -ArgumentList @('"' + $entry + '"', '--sample') `
        -WorkingDirectory $workspace -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $runtime 'shared-backend-startup.log') `
        -RedirectStandardError (Join-Path $runtime 'shared-backend-startup-error.log')
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $health = Get-BackendHealth
        if ($null -ne $health) {
            Confirm-Backend $health
            Write-Output 'AccessTransit localhost backend is ready.'
            exit 0
        }
        if ($process.HasExited) {
            throw 'Backend startup failed. See .dart_tool/shared-backend-startup-error.log. No app data was cleared.'
        }
        Start-Sleep -Seconds 1
    }
    throw 'Backend did not become ready. Check .dart_tool/shared-backend-startup-error.log and retry.'
} finally {
    $lock.Dispose()
}
