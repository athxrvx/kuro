# Kuro dotfiles

Personal Arch Linux desktop configuration for Hyprland, QuickShell, Kitty, Kuro, Zsh, and Neovim. The bundle includes the active `~/.config` settings, `~/.zshrc`, `~/.zshenv`, and portable scripts from `~/.local/bin`.

## Install the dotfiles

```sh
cd ~/kuro
./installer-dots --dry-run
./installer-dots
```

The installer copies bundled config into `~/.config`, home dotfiles into `~`, and scripts into `~/.local/bin`. Matching existing destinations are backed up under `~/kuro-backups/<timestamp>` first. It does not install packages or use root privileges.

## Install dependencies

```sh
./installer-deps --dry-run
./installer-deps
```

The dependency installer targets Arch Linux, lists the packages, and asks before running `pacman -Syu --needed`. It does not enable or start services.

## Refresh this repository from the current machine

```sh
~/kuro/refresh-bundle.sh
```

This refreshes the tracked bundle from active config, home Zsh/GTK startup files, local scripts, and the Orchis GTK theme. It uses `git rm` for tracked paths whose source has been removed, then stages the refreshed bundle for review. It skips Codex and browser profiles, PulseAudio runtime state, service credentials, Kuro's separate Flea source checkout, Git/agent metadata, Zsh cache/history, and locally installed `fzf` and `mise` binaries. It does not commit or push.

## Notes

- GTK 3/4 settings, the home GTK theme file, and Orchis GTK 2/3/4 stylesheets are bundled. The installer places Orchis under `~/.local/share/themes/Orchis-Dark` and recreates GTK 4/libadwaita stylesheet links there.
- Review machine-specific monitor, wallpaper, and app paths before installing on another system.
- The Zsh config expects the bundled `~/.config/zsh` tree and uses Kuro's AF-Magic inspired prompt.
- `installer-deps` installs the four Nerd Font families selectable by the Kuro font picker.
