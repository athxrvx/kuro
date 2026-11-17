#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./installpkg.sh [--dry-run]

Installs the Arch Linux packages used by this Hyprland/Quickshell setup.
The install uses pacman -Syu to avoid a partial system upgrade.
EOF
}

dry_run=0
case "${1:-}" in
    "") ;;
    --dry-run) dry_run=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null 2>&1; then
    echo "This package installer supports Arch Linux only." >&2
    exit 1
fi

# Runtime and configured feature tools for this desktop.
packages=(
    hyprland hypridle quickshell kitty
    networkmanager bluez bluez-utils wireplumber
    cliphist wl-clipboard playerctl rofi
    brightnessctl hyprsunset awww
    grim slurp hyprpicker gpu-screen-recorder
    upower power-profiles-daemon libnotify jq
    python ttf-jetbrains-mono-nerd noto-fonts-cjk
)

echo "Packages to install:"
printf '  %s\n' "${packages[@]}"
echo
echo "This will run a full Arch system upgrade (pacman -Syu) before installing the packages."

if (( dry_run )); then
    echo "Dry run only; no packages were installed."
    exit 0
fi

read -r -p "Continue? [y/N] " answer
case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
esac

if (( EUID == 0 )); then
    pacman -Syu --needed -- "${packages[@]}"
else
    command -v sudo >/dev/null 2>&1 || { echo "Install sudo or run this script as root." >&2; exit 1; }
    sudo pacman -Syu --needed -- "${packages[@]}"
fi
