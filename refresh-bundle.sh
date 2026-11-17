#!/usr/bin/env bash
set -euo pipefail

bundle_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_source="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$bundle_dir/config" "$bundle_dir/local/bin"
for source in "$config_source"/*; do
    [[ -e "$source" || -L "$source" ]] || continue
    name="${source##*/}"
    case "$name" in
        Codex|mozilla|pulse) continue ;;
    esac
    cp -a -- "$source" "$bundle_dir/config/"
done

# Skip repository/agent metadata that may be injected into working folders.
find "$bundle_dir/config" -type d \( -name .git -o -name .codex -o -name .agents -o -name .aws \) \
    -prune -exec rm -rf -- {} +

if [[ -d "$HOME/.local/bin" ]]; then
    cp -a -- "$HOME/.local/bin/." "$bundle_dir/local/bin/"
fi

echo "Bundle refreshed from $config_source and $HOME/.local/bin."
echo "Removed source files are not deleted from the bundle; review config/ and local/bin/ if you removed any."
