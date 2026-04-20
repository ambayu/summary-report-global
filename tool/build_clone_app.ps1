param(
    [Parameter(Mandatory = $true)]
    [string]$BundlePath,

    [Alias("Target")]
    [ValidateSet("apk", "appbundle")]
    [string]$BuildTarget = "apk"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedBundlePath = (Resolve-Path -LiteralPath $BundlePath).Path
$bundleJson = Get-Content -LiteralPath $resolvedBundlePath -Raw | ConvertFrom-Json

if (-not $bundleJson.cafeName) {
    throw "Field 'cafeName' wajib ada di bundle clone app."
}
if (-not $bundleJson.appId) {
    throw "Field 'appId' wajib ada di bundle clone app."
}
if (-not $bundleJson.logoBase64) {
    throw "Field 'logoBase64' wajib ada di bundle clone app."
}

$appIdPattern = '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$'
if ($bundleJson.appId -notmatch $appIdPattern) {
    throw "Package ID clone tidak valid: $($bundleJson.appId)"
}

$buildRoot = Join-Path $repoRoot "build\clone_app"
$workRoot = Join-Path $buildRoot "workspace"
$backupRoot = Join-Path $buildRoot "backup"
$outputRoot = Join-Path $buildRoot "output"
$iconPath = Join-Path $workRoot "clone_app_icon.png"
$launcherConfigPath = Join-Path $workRoot "launcher_icons_clone.yaml"
$mipmapBackup = Join-Path $backupRoot "res"
$androidResPath = Join-Path $repoRoot "android\app\src\main\res"

New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$logoBytes = [Convert]::FromBase64String([string]$bundleJson.logoBase64)
[IO.File]::WriteAllBytes($iconPath, $logoBytes)

if (Test-Path -LiteralPath $mipmapBackup) {
    Remove-Item -LiteralPath $mipmapBackup -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $mipmapBackup | Out-Null
Get-ChildItem -Path $androidResPath -Directory -Filter "mipmap*" | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $mipmapBackup -Recurse -Force
}

$yamlIconPath = $iconPath.Replace('\', '/')
@"
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "$yamlIconPath"
  adaptive_icon_background: "#B3261E"
  adaptive_icon_foreground: "$yamlIconPath"
"@ | Set-Content -LiteralPath $launcherConfigPath -NoNewline

$env:APP_ID = [string]$bundleJson.appId
$env:APP_NAME = [string]$bundleJson.cafeName

$buildCommand = if ($BuildTarget -eq "appbundle") { "appbundle" } else { "apk" }
$outputFile = if ($BuildTarget -eq "appbundle") {
    Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
} else {
    Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
}

$safeName = ([string]$bundleJson.cafeName) -replace '[^a-zA-Z0-9]+', '_'
$finalOutput = if ($BuildTarget -eq "appbundle") {
    Join-Path $outputRoot "$safeName-release.aab"
} else {
    Join-Path $outputRoot "$safeName-release.apk"
}

try {
    Push-Location $repoRoot

    & dart run flutter_launcher_icons -f $launcherConfigPath
    if ($LASTEXITCODE -ne 0) {
        throw "Gagal generate launcher icon clone app."
    }

    & flutter build $buildCommand --release
    if ($LASTEXITCODE -ne 0) {
        throw "Gagal build clone app."
    }

    if (-not (Test-Path -LiteralPath $outputFile)) {
        throw "File hasil build tidak ditemukan: $outputFile"
    }

    Copy-Item -LiteralPath $outputFile -Destination $finalOutput -Force
    Write-Host ""
    Write-Host "Clone app berhasil dibuild." -ForegroundColor Green
    Write-Host "Nama App   : $($bundleJson.cafeName)"
    Write-Host "Package ID : $($bundleJson.appId)"
    Write-Host "Output     : $finalOutput"
}
finally {
    Get-ChildItem -Path $androidResPath -Directory -Filter "mipmap*" | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
    Get-ChildItem -Path $mipmapBackup -Directory -Filter "mipmap*" | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $androidResPath -Recurse -Force
    }

    Remove-Item Env:APP_ID -ErrorAction SilentlyContinue
    Remove-Item Env:APP_NAME -ErrorAction SilentlyContinue

    Pop-Location
}
