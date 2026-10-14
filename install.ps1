$ErrorActionPreference = 'Stop'

if (-not $env:APPDATA) {
    throw 'Run install.ps1 on Windows. Use install.sh on Linux or macOS.'
}

$repoRoot = $PSScriptRoot
$downloadRoot = $null
$configFiles = 'vscode/settings.json', 'vscode/extensions.txt', 'emacs/init.el'

try {
    if ([string]::IsNullOrEmpty($repoRoot)) {
        # Invoke-Expression has no script directory. Fetch the companion files first.
        $downloadRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-" + [guid]::NewGuid().ToString('N'))
        $repoRoot = $downloadRoot
        foreach ($file in $configFiles) {
            $destination = Join-Path $repoRoot $file
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cavanau/dotfiles/main/$file" -UseBasicParsing -OutFile $destination
        }
    }

    foreach ($file in $configFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
            throw "Missing $file. Run this script from a complete dotfiles checkout."
        }
    }

    function Install-Config {
        param([string]$Source, [string]$Destination)

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
        if (Test-Path -LiteralPath $Destination) {
            $backup = "$Destination.backup-$([guid]::NewGuid().ToString('N'))"
            Copy-Item -LiteralPath $Destination -Destination $backup
            Write-Host "Backup: $backup"
        }
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "Installed: $Destination"
    }

    $codeSettings = Join-Path $env:APPDATA 'Code/User/settings.json'
    $codiumSettings = Join-Path $env:APPDATA 'VSCodium/User/settings.json'
    $code = Get-Command code -CommandType Application -ErrorAction SilentlyContinue
    $codium = Get-Command codium -CommandType Application -ErrorAction SilentlyContinue
    $hasCode = $code -or (Test-Path -LiteralPath (Split-Path -Parent $codeSettings))
    $hasCodium = $codium -or (Test-Path -LiteralPath (Split-Path -Parent $codiumSettings))

    # Default to VS Code when neither editor is installed yet.
    if (-not $hasCode -and -not $hasCodium) { $hasCode = $true }

    function Install-Editor {
        param([string]$Settings, [string]$Cli)

        Install-Config (Join-Path $repoRoot 'vscode/settings.json') $Settings
        $command = Get-Command $Cli -CommandType Application -ErrorAction SilentlyContinue
        if (-not $command) {
            Write-Host "Install extensions from vscode/extensions.txt once $Cli is on PATH."
            return
        }
        foreach ($line in Get-Content -LiteralPath (Join-Path $repoRoot 'vscode/extensions.txt')) {
            $extension = $line.Trim()
            if (-not $extension -or $extension.StartsWith('#')) { continue }
            & $command.Source --install-extension $extension
            if ($LASTEXITCODE -ne 0) { Write-Warning "Could not install extension: $extension" }
        }
    }

    if ($hasCode) { Install-Editor $codeSettings 'code' }
    if ($hasCodium) { Install-Editor $codiumSettings 'codium' }
    Install-Config (Join-Path $repoRoot 'emacs/init.el') (Join-Path $HOME '.emacs')

    Write-Host 'Done. Restart your editors to load the settings.'
}
finally {
    if ($downloadRoot -and (Test-Path -LiteralPath $downloadRoot)) {
        Remove-Item -LiteralPath $downloadRoot -Recurse -Force
    }
}
