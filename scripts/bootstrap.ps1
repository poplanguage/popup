[CmdletBinding()]
param(
    [switch]$NoModifyPath
)

$ErrorActionPreference = 'Stop'
$Repository = 'poplanguage/popup'
$PopupVersion = $env:POPUP_VERSION
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
    return "$arch-pc-windows-msvc"
}

function Get-Release {
    $headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'popup-installer' }
    if ([string]::IsNullOrWhiteSpace($PopupVersion)) {
        return @(Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases?per_page=1" -Headers $headers)[0]
    }
    return Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/tags/$PopupVersion" -Headers $headers
}

function Main {
    $target = Get-Target
    Write-Host 'info: fetching Popup release metadata from GitHub'
    $release = Get-Release
    if ($null -eq $release) { Fail 'no Popup release is published on GitHub' }
    $archiveName = "popup-$target.zip"
    $archiveAsset = @($release.assets | Where-Object { $_.name -eq $archiveName }) | Select-Object -First 1
    $checksumAsset = @($release.assets | Where-Object { $_.name -eq "$archiveName.sha256" }) | Select-Object -First 1
    if ($null -eq $archiveAsset) { Fail "no popup archive for $target is published on GitHub" }
    if ($null -eq $checksumAsset) { Fail "no SHA-256 sidecar for $archiveName is published on GitHub" }

    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("popup-" + [Guid]::NewGuid())
    try {
        New-Item -ItemType Directory -Force -Path $temp | Out-Null
        $archive = Join-Path $temp 'popup.zip'
        $checksum = Join-Path $temp 'popup.zip.sha256'
        Invoke-WebRequest -Uri $archiveAsset.browser_download_url -OutFile $archive
        Invoke-WebRequest -Uri $checksumAsset.browser_download_url -OutFile $checksum
        $fields = (Get-Content -Raw $checksum).Trim() -split '\s+'
        if ($fields.Count -ne 2 -or $fields[0] -notmatch '^[0-9a-fA-F]{64}$' -or [System.IO.Path]::GetFileName($fields[1].TrimStart('*')) -ne $archiveName) {
            Fail "invalid SHA-256 sidecar for $archiveName"
        }
        $actual = (Get-FileHash -Algorithm SHA256 -Path $archive).Hash.ToLowerInvariant()
        if ($actual -ne $fields[0].ToLowerInvariant()) { Fail 'SHA-256 verification failed for popup' }
        $unpacked = Join-Path $temp 'unpacked'
        Expand-Archive -Path $archive -DestinationPath $unpacked -Force
        $binary = Join-Path $unpacked "popup-$target.exe"
        if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) { Fail "archive did not contain popup-$target.exe" }
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
