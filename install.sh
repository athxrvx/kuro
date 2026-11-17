#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run]

Copies the bundled user configuration into ~/.config and ~/.local/bin.
Existing matching files are backed up under ~/kuro-backups/<timestamp>/.
No packages are installed and no root privileges are used.
EOF
}

dry_run=0
case "${1:-}" in
    "") ;;
    --dry-run) dry_run=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

bundle_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_root="$HOME/kuro-backups/$(date +%Y%m%d-%H%M%S)"
backup_made=0

backup_if_present() {
    local source_path="$1" relative_path="$2" destination="$3"
    if [[ -e "$destination" || -L "$destination" ]]; then
        if (( dry_run )); then
            printf 'Would back up %s to %s\n' "$destination" "$backup_root/$relative_path"
        else
            mkdir -p "$(dirname -- "$backup_root/$relative_path")"
            cp -a -- "$destination" "$backup_root/$relative_path"
            backup_made=1
        fi
    fi
}

install_tree() {
    local source="$1" destination="$2" relative="$3"
    [[ -d "$source" ]] || return 0
    backup_if_present "$source" "$relative" "$destination"
    if (( dry_run )); then
        printf 'Would install %s to %s\n' "$source" "$destination"
    else
        mkdir -p "$destination"
        cp -a -- "$source/." "$destination/"
    fi
}

install_entry() {
    local source="$1" destination="$2" relative="$3"
    backup_if_present "$source" "$relative" "$destination"
    if (( dry_run )); then
        printf 'Would install %s to %s\n' "$source" "$destination"
    else
        mkdir -p "$(dirname -- "$destination")"
        cp -a -- "$source" "$destination"
    fi
}

[[ -d "$bundle_dir/config" ]] || { echo "Bundle is missing its config directory." >&2; exit 1; }

while IFS= read -r -d '' source; do
    name="${source##*/}"
    install_tree "$source" "$config_home/$name" ".config/$name"
done < <(find "$bundle_dir/config" -mindepth 1 -maxdepth 1 -print0 | sort -z)

if [[ -d "$bundle_dir/local/bin" ]]; then
    while IFS= read -r -d '' source; do
        name="${source##*/}"
        install_entry "$source" "$HOME/.local/bin/$name" ".local/bin/$name"
    done < <(find "$bundle_dir/local/bin" -mindepth 1 -maxdepth 1 -print0 | sort -z)
fi

# Rebuild the two convenience links so they point into this user's home,
# instead of retaining the source machine's absolute symlink targets.
for name in controlcenter bar-layout; do
    target="$config_home/quickshell/shell/bin/$name"
    if [[ -e "$target" ]]; then
        if (( dry_run )); then
            printf 'Would link %s to %s\n' "$HOME/.local/bin/$name" "$target"
        else
            mkdir -p "$HOME/.local/bin"
            ln -sfn -- "$target" "$HOME/.local/bin/$name"
        fi
    fi
done

if (( dry_run )); then
    echo "Dry run complete; no files were changed."
else
    (( backup_made )) && echo "Existing files backed up to: $backup_root"
    echo "Configuration installed. Review README-INSTALL.md for dependencies and machine-specific settings."
fi
