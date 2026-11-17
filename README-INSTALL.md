# Kuro configuration bundle

This bundle contains the current user configuration directories and `~/.local/bin` utilities. It excludes the Codex app profile and Mozilla/Firefox profile data, PulseAudio's runtime cookie, and repository/agent metadata. Those contain app state, private browser data, session credentials, or workspace metadata rather than portable configuration.

## Install

Copy this folder to the destination system, then run:

```sh
cd ~/kuro
./install.sh --dry-run
./install.sh
```

The installer copies matching configuration into `~/.config` and utilities into `~/.local/bin`. Existing matching files are preserved in `~/kuro-backups/<timestamp>/`. It does not use `sudo`, install packages, remove unrelated files, or overwrite files outside those two user directories.

The bundled `controlcenter` and `bar-layout` links are recreated to point to the installed Quickshell scripts under the destination user's home directory.

On Arch Linux, install the packages used by this setup with:

```sh
./installpkg.sh
```

The script lists the packages and asks before proceeding. It runs `pacman -Syu --needed` to keep the system fully upgraded while installing them. Use `./installpkg.sh --dry-run` to print the list without changing the system. It does not enable or start services.

## Refresh this bundle on the source system

After changing the active configuration, run:

```sh
~/kuro/refresh-bundle.sh
```

It recopies the current `~/.config` entries and `~/.local/bin` utilities. It skips the Codex and Mozilla profiles, PulseAudio's runtime cookie, and repository/agent metadata. It overlays current files but does not delete bundle files whose source was removed; remove those from `config/` or `local/bin/` manually if needed.

## Notes

- The Quickshell and Hyprland configuration expects the relevant applications and services to be installed on the destination system. See `config/quickshell/shell/README.md` for the component dependency list.
- Machine-specific monitor layouts, wallpaper locations, theme paths, and application availability may need adjustment after installation.
- The current Hyprland/Quickshell configuration references `~/.local/bin/wallset-backend`, but that file is not present in the source system's `~/.local/bin`; wallpaper changes that use that command will need a wallpaper backend configured on the destination.
