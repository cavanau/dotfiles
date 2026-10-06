## Windows powershell

    iwr https://raw.githubusercontent.com/cavanau/dotfiles/main/install.ps1 -UseBasicParsing | ForEach-Object Content | iex


## Linux

    curl -fsSL https://raw.githubusercontent.com/cavanau/dotfiles/main/install.sh | bash

The installers copy `vscode/settings.json` to VS Code and/or VSCodium when detected, and install the listed extensions through each available `code` or `codium` command.
