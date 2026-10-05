#!/usr/bin/env bash
set -euo pipefail

repo_url='https://github.com/cavanau/dotfiles.git'
script_dir=''
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi

repo_root="$script_dir"
temp_root=''
if [[ ! -f "$repo_root/vscode/settings.json" || ! -f "$repo_root/emacs/init.el" ]]; then
  command -v git >/dev/null 2>&1 || {
    echo 'Git is required. Install Git, then rerun this installer.' >&2
    exit 1
  }
  temp_root="$(mktemp -d "${TMPDIR:-/tmp}/cavanau-dotfiles.XXXXXX")"
  git clone --depth 1 "$repo_url" "$temp_root"
  repo_root="$temp_root"
fi

backup_and_copy() {
  local source="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -p "$destination" "$destination.backup-$stamp"
    echo "Backed up existing file: $destination.backup-$stamp"
  fi
  cp "$source" "$destination"
  echo "Installed: $destination"
}

case "$(uname -s)" in
  Darwin)
    vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    emacs_init="$HOME/.emacs.d/init.el"
    ;;
  *)
    vscode_settings="$HOME/.config/Code/User/settings.json"
    emacs_init="$HOME/.emacs.d/init.el"
    ;;
esac

backup_and_copy "$repo_root/vscode/settings.json" "$vscode_settings"
backup_and_copy "$repo_root/emacs/init.el" "$emacs_init"

if command -v code >/dev/null 2>&1; then
  while IFS= read -r extension; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    code --install-extension "$extension" || echo "VS Code could not install extension: $extension" >&2
  done < "$repo_root/vscode/extensions.txt"
else
  echo 'The code command was not found. Open VS Code and install the extensions listed in vscode/extensions.txt.'
fi

echo 'Dotfiles installation complete. Restart VS Code and Emacs to load the new settings.'

if [[ -n "$temp_root" ]]; then
  rm -rf "$temp_root"
fi
