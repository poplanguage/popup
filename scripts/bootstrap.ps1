[CmdletBinding()]
param(
    [switch]$NoModifyPath
)

$ErrorActionPreference = 'Stop'
$IndexUrl = $env:POP_INDEX_URL
if ([string]::IsNullOrWhiteSpace($IndexUrl)) { $IndexUrl = 'https://pop.squareweb.app' }
$IndexUrl = $IndexUrl.TrimEnd('/')
$InstallDir = $env:POPUP_HOME
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $env:USERPROFILE '.popup'
}

function Fail([string]$Message) { throw "popup installer: $Message" }

function Get-Target {
    $arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()) {
        'x64' { 'x86_64' }
        'arm64' { 'aarch64' }
        default { Fail "unsupported architecture: $_" }
    }
    return @{ Os = 'windows'; Arch = $arch; Triple = "$arch-pc-windows-msvc" }
}

function Main {
    $target = Get-Target
    Write-Host "info: fetching Popup manifest from $IndexUrl"
    $manifest = Invoke-RestMethod -Uri "$IndexUrl/v1/releases/latest/manifest?product=popup" -Headers @{ Accept = 'application/json' }
    $artifact = @($manifest.artifacts | Where-Object {
        $_.available -eq $true -and $_.archive_format -eq 'zip' -and $_.target.os -eq $target.Os -and $_.target.arch -eq $target.Arch
    }) | Select-Object -First 1
    if ($null -eq $artifact) { Fail "no popup archive for $($target.Triple) is published by the Pop Index" }
    if ($artifact.sha256 -notmatch '^[0-9a-fA-F]{64}$') { Fail 'published popup artifact has an invalid SHA-256' }

    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("popup-" + [Guid]::NewGuid())
    try {
        New-Item -ItemType Directory -Force -Path $temp | Out-Null
        $archive = Join-Path $temp 'popup.zip'
        $url = if ($artifact.url -match '^https?://') { $artifact.url } else { "$IndexUrl/$($artifact.url.TrimStart('/'))" }
        Invoke-WebRequest -Uri $url -OutFile $archive
        $actual = (Get-FileHash -Algorithm SHA256 -Path $archive).Hash.ToLowerInvariant()
        if ($actual -ne $artifact.sha256.ToLowerInvariant()) { Fail 'SHA-256 verification failed for popup' }
        $unpacked = Join-Path $temp 'unpacked'
        Expand-Archive -Path $archive -DestinationPath $unpacked -Force
        $binary = Join-Path $unpacked "popup-$($target.Triple).exe"
        if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) { Fail "archive did not contain popup-$($target.Triple).exe" }
        $binDir = Join-Path $InstallDir 'bin'
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
        Copy-Item -LiteralPath $binary -Destination (Join-Path $binDir 'popup.exe') -Force
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
    }

    if (-not $NoModifyPath) {
        [Environment]::SetEnvironmentVariable('POPUP_HOME', $InstallDir, 'User')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ((@($userPath -split ';') -notcontains $binDir)) {
            [Environment]::SetEnvironmentVariable('Path', (($userPath.TrimEnd(';') + ';' + $binDir).TrimStart(';')), 'User')
        }
        $env:POPUP_HOME = $InstallDir
        if ((@($env:Path -split ';') -notcontains $binDir)) { $env:Path = "$binDir;$env:Path" }
        Write-Host 'info: added popup to your user environment; open a new terminal to use it.'
    }
    Write-Host "info: installed popup to $(Join-Path $InstallDir 'bin\\popup.exe')"
}

Main
