$ErrorActionPreference = 'Stop'

$repoUrl = 'https://github.com/cavanau/dotfiles.git'
$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { '' }
$tempRoot = $null

try {
    $hasLocalFiles = $repoRoot -and
        (Test-Path -LiteralPath (Join-Path $repoRoot 'vscode/settings.json')) -and
        (Test-Path -LiteralPath (Join-Path $repoRoot 'emacs/init.el'))
    if (-not $hasLocalFiles) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw 'Git is required. Install Git for Windows, then rerun this installer.'
        }

        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cavanau-dotfiles-" + [guid]::NewGuid().ToString('N'))
        & git clone --depth 1 $repoUrl $tempRoot
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not clone https://github.com/cavanau/dotfiles.git'
        }
        $repoRoot = $tempRoot
    }

    function Copy-WithBackup {
        param(
            [Parameter(Mandatory = $true)][string]$Source,
            [Parameter(Mandatory = $true)][string]$Destination
        )

        $destinationDirectory = Split-Path -Parent $Destination
        New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null

        if (Test-Path -LiteralPath $Destination) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Copy-Item -LiteralPath $Destination -Destination "$Destination.backup-$stamp" -Force
            Write-Host "Backed up existing file: $Destination.backup-$stamp"
        }

        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "Installed: $Destination"
    }

    $vscodeSettings = Join-Path $env:APPDATA 'Code\User\settings.json'
    $emacsInit = Join-Path $HOME '.emacs'
    Copy-WithBackup (Join-Path $repoRoot 'vscode/settings.json') $vscodeSettings
    Copy-WithBackup (Join-Path $repoRoot 'emacs/init.el') $emacsInit

    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCommand) {
        Get-Content -LiteralPath (Join-Path $repoRoot 'vscode/extensions.txt') |
            Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } |
            ForEach-Object {
                & $codeCommand.Source --install-extension $_.Trim()
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "VS Code could not install extension: $_"
                }
            }
    }
    else {
        Write-Host 'The code command was not found. Open VS Code and install the extensions listed in vscode/extensions.txt.'
    }

    Write-Host 'Dotfiles installation complete. Restart VS Code and Emacs to load the new settings.'
}
finally {
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        $resolvedTemp = (Resolve-Path -LiteralPath $tempRoot).Path
        $tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if ($resolvedTemp.StartsWith($tempBase, [System.StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path -Leaf $resolvedTemp).StartsWith('cavanau-dotfiles-', [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
        }
    }
}
