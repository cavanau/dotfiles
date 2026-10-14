#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for file in vscode/settings.json vscode/extensions.txt emacs/init.el; do
  if [[ ! -f "$repo_root/$file" ]]; then
    echo "Missing $file. Run this script from a complete dotfiles checkout." >&2
    exit 1
  fi
done

install_config() {
  local source="$1" destination="$2" backup
  mkdir -p "$(dirname -- "$destination")"
  if [[ -e "$destination" || -L "$destination" ]]; then
    backup="$(mktemp "$destination.backup-XXXXXX")"
    cp -p "$destination" "$backup"
    echo "Backup: $backup"
  fi
  cp "$source" "$destination"
  echo "Installed: $destination"
}

case "$(uname -s)" in
  Darwin) config_root="$HOME/Library/Application Support" ;;
  *) config_root="${XDG_CONFIG_HOME:-$HOME/.config}" ;;
esac
code_settings="$config_root/Code/User/settings.json"
codium_settings="$config_root/VSCodium/User/settings.json"
has_code=false
has_codium=false
if command -v code >/dev/null 2>&1 || [[ -d "$(dirname -- "$code_settings")" ]]; then
  has_code=true
fi
if command -v codium >/dev/null 2>&1 || [[ -d "$(dirname -- "$codium_settings")" ]]; then
  has_codium=true
fi

# Default to VS Code when neither editor is installed yet.
if [[ "$has_code" == false && "$has_codium" == false ]]; then has_code=true; fi

install_editor() {
  local settings="$1" cli="$2" extension
  install_config "$repo_root/vscode/settings.json" "$settings"
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "Install extensions from vscode/extensions.txt once $cli is on PATH."
    return
  fi
  while IFS= read -r extension || [[ -n "$extension" ]]; do
    extension="${extension%$'\r'}"
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    "$cli" --install-extension "$extension" || echo "Could not install extension: $extension" >&2
  done < "$repo_root/vscode/extensions.txt"
}

if [[ "$has_code" == true ]]; then install_editor "$code_settings" code; fi
if [[ "$has_codium" == true ]]; then install_editor "$codium_settings" codium; fi
install_config "$repo_root/emacs/init.el" "$HOME/.emacs.d/init.el"

echo 'Done. Restart your editors to load the settings.'
