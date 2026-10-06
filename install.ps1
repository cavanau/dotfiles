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
    $codiumSettings = Join-Path $env:APPDATA 'VSCodium\User\settings.json'
    $emacsInit = Join-Path $HOME '.emacs'

    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    $codiumCommand = Get-Command codium -ErrorAction SilentlyContinue
    $hasCode = $codeCommand -or (Test-Path -LiteralPath (Split-Path -Parent $vscodeSettings))
    $hasCodium = $codiumCommand -or (Test-Path -LiteralPath (Split-Path -Parent $codiumSettings))
    if (-not $hasCode -and -not $hasCodium) {
        $hasCode = $true
    }

    if ($hasCode) {
        Copy-WithBackup (Join-Path $repoRoot 'vscode/settings.json') $vscodeSettings
    }
    if ($hasCodium) {
        Copy-WithBackup (Join-Path $repoRoot 'vscode/settings.json') $codiumSettings
    }
    Copy-WithBackup (Join-Path $repoRoot 'emacs/init.el') $emacsInit

    foreach ($editor in @(
        @{ Name = 'VS Code'; Command = $codeCommand; Enabled = $hasCode },
        @{ Name = 'VSCodium'; Command = $codiumCommand; Enabled = $hasCodium }
    )) {
        if ($editor.Command) {
            Get-Content -LiteralPath (Join-Path $repoRoot 'vscode/extensions.txt') |
                Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } |
                ForEach-Object {
                    & $editor.Command.Source --install-extension $_.Trim()
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "$($editor.Name) could not install extension: $_"
                    }
                }
            }
        elseif ($editor.Enabled) {
            $cliName = if ($editor.Name -eq 'VS Code') { 'code' } else { 'codium' }
            Write-Host "The $cliName command was not found. Open $($editor.Name) and install extensions listed in vscode/extensions.txt."
        }
    }

    Write-Host 'Dotfiles installation complete. Restart VS Code or VSCodium and Emacs to load the new settings.'
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
