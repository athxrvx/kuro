pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Declarative catalogue for the launcher. This is now the only settings UI:
// the old Control Center pages live here as nested sections.
//
// Result shape used by the UI:
//   { title, sub, glyph, keys, hint, danger, check?, run: { type, ... } }
// Live device rows are added by services/LauncherControls.qml.
Singleton {
    id: root

    function g(cp) { return Icons.g(cp) }

    readonly property var sections: buildSections()

    function buildSections() {
        const list = baseSections();

        const themes = list.find(s => s.id === "style-themes");
        if (themes) {
            themes.items = (Config.kuroSchemes ?? []).map(t => ({
                id: "theme_" + t.id,
                title: t.name,
                sub: "Colorscheme",
                glyph: t.id === Config.kuroScheme ? g(0xF012C) : g(0xF03D8),
                keys: "theme colorscheme color scheme " + t.id + " " + t.name,
                hint: t.id === Config.kuroScheme ? "active" : "",
                run: { type: "kuroScheme", name: t.id }
            })).concat(themes.items);
        }
        return list;
    }

    function baseSections() {
        return [
        // ── 01 Apps ──────────────────────────────────────────────────
        {
            id: "apps", num: "01", label: "Apps",
            sub: "Installed applications and launchers",
            glyph: g(0xF003B),                                   // md-apps
            keys: "applications launchers desktop entries favorites recent",
            items: [
                {
                    id: "appAll", title: "All applications",
                    sub: "Browse installed .desktop entries",
                    glyph: g(0xF003B), keys: "list browse programs",
                    hint: "apps", run: { type: "section", section: "apps" }
                },
                {
                    id: "appInstall", title: "Install an application",
                    sub: "fzpac  ·  fuzzy menu, then install in a floating terminal",
                    glyph: g(0xF03D4), keys: "add get install package fzf",  // md-package_down
                    hint: "fzpac", danger: true,
                    run: { type: "tui", mode: "S" }
                },
                {
                    id: "appRemove", title: "Uninstall an application",
                    sub: "fzpac  ·  fuzzy menu, then remove in a floating terminal",
                    glyph: g(0xF01B4), keys: "remove uninstall delete fzf",  // md-trash_can
                    hint: "fzpac", danger: true,
                    run: { type: "tui", mode: "R" }
                },
                {
                    id: "appDesktop", title: "Applications folder",
                    sub: "/usr/share/applications",
                    glyph: g(0xF0770), keys: "desktop entries location files",  // md-folder_open
                    hint: "files", check: "test -d /usr/share/applications",
                    run: { type: "url", url: "file:///usr/share/applications" }
                }
            ]
        },

        // ── 02 Control ───────────────────────────────────────────────
        {
            id: "control", num: "02", label: "Control",
            sub: "Network, Bluetooth, sound and display",
            glyph: Icons.wifi,
            keys: "control devices network wifi bluetooth sound audio display brightness",
            items: [
                {
                    id: "devProfile", title: "System profile",
                    sub: "CPU, memory, temperature, uptime and battery",
                    glyph: Icons.cpu, keys: "profile telemetry system cpu memory temperature",
                    hint: "browse", run: { type: "enterSection", id: "dev-profile" }
                },
                {
                    id: "devNetwork", title: "Network",
                    sub: "Wi-Fi, scanning, Ethernet and saved networks",
                    glyph: Icons.wifi, keys: "wifi wireless ethernet network nmcli internet",
                    hint: "browse", run: { type: "enterSection", id: "dev-network" }
                },
                {
                    id: "devBluetooth", title: "Bluetooth",
                    sub: "Radio power and paired devices",
                    glyph: Icons.bluetooth, keys: "bluetooth headset pair devices wireless",
                    hint: "browse", run: { type: "enterSection", id: "dev-bluetooth" }
                },
                {
                    id: "devSound", title: "Sound",
                    sub: "Volume, mute, microphones and output devices",
                    glyph: Icons.volume, keys: "sound audio volume speaker microphone mic mute wpctl",
                    hint: "browse", run: { type: "enterSection", id: "dev-sound" }
                },
                {
                    id: "devDisplay", title: "Display",
                    sub: "Brightness, night light and external screens",
                    glyph: Icons.brightness, keys: "display brightness night light screen monitor resolution",
                    hint: "browse", run: { type: "enterSection", id: "dev-display" }
                }
            ]
        },

        // ── 03 Setup ─────────────────────────────────────────────────
        {
            id: "setup", num: "03", label: "Setup",
            sub: "Desktop configuration and installation",
            glyph: g(0xF0493),                                   // md-cog
            keys: "configure install desktop components dotfiles",
            items: [
                // Desktop
                {
                    id: "setupHypr", title: "Hyprland config",
                    sub: "Desktop · ~/.config/hypr/hyprland.lua",
                    glyph: g(0xF08C7), keys: "hyprland compositor desktop config",  // md-arch
                    hint: "config", check: "test -f \"$HOME/.config/hypr/hyprland.lua\"",
                    run: { type: "url", url: "file://" + Config.home + "/.config/hypr/hyprland.lua" }
                },
                {
                    id: "setupReload", title: "Reload Hyprland",
                    sub: "Desktop · apply config changes now",
                    glyph: g(0xF0450), keys: "reload refresh desktop config",  // md-refresh
                    hint: "cmd", check: "command -v hyprctl >/dev/null",
                    run: { type: "cmd", cmd: ["hyprctl", "reload"] }
                },
                {
                    id: "setupShell", title: "Shell config",
                    sub: "Shell · ~/.zshrc or ~/.bashrc",
                    glyph: g(0xF018D), keys: "zsh bash fish shell config prompt",  // md-console
                    hint: "config", check: "test -f \"$HOME/.zshrc\" || test -f \"$HOME/.bashrc\"",
                    run: { type: "url", url: "file://" + Config.home + "/.zshrc" }
                },
                // Terminal
                {
                    id: "setupKitty", title: "Kitty config",
                    sub: "Terminal · ~/.config/kitty/kitty.conf",
                    glyph: g(0xF489), keys: "kitty terminal font config",  // oct-terminal
                    hint: "config", check: "test -f \"$HOME/.config/kitty/kitty.conf\"",
                    run: { type: "url", url: "file://" + Config.home + "/.config/kitty/kitty.conf" }
                },
                {
                    id: "setupTerm", title: "Open a terminal",
                    sub: "Terminal · kitty",
                    glyph: g(0xF489), keys: "terminal shell console kitty",
                    hint: "cmd", check: "command -v kitty >/dev/null",
                    run: { type: "cmd", cmd: ["kitty"] }
                },
                // Development
                {
                    id: "setupGit", title: "Git config",
                    sub: "Development · ~/.gitconfig",
                    glyph: g(0xF062C), keys: "git version control development config",
                    hint: "config", check: "test -f \"$HOME/.gitconfig\"",
                    run: { type: "url", url: "file://" + Config.home + "/.gitconfig" }
                },
                {
                    id: "setupNvim", title: "Neovim config",
                    sub: "Development · ~/.config/nvim",
                    glyph: g(0xF36F), keys: "neovim nvim editor development config",  // linux-neovim
                    hint: "config", check: "test -d \"$HOME/.config/nvim\"",
                    run: { type: "url", url: "file://" + Config.home + "/.config/nvim" }
                },
                // Input / Audio / Network / Utilities
                {
                    id: "setupKeys", title: "Keybindings",
                    sub: "Input · shortcuts and hotkeys",
                    glyph: Icons.keyboard, keys: "keyboard input shortcuts keybinds",
                    hint: "browse", run: { type: "enterSection", id: "sys-keybinds" }
                },
                {
                    id: "setupAudio", title: "Audio devices",
                    sub: "Audio · PipeWire / WirePlumber",
                    glyph: Icons.volume, keys: "pipewire wireplumber sound audio microphone",
                    hint: "browse", check: "command -v wireplumber >/dev/null",
                    run: { type: "enterSection", id: "dev-sound" }
                },
                {
                    id: "setupBt", title: "Bluetooth devices",
                    sub: "Input · pair headsets and controllers",
                    glyph: Icons.bluetooth, keys: "bluetooth pair headset earbuds device",
                    hint: "browse", run: { type: "enterSection", id: "dev-bluetooth" }
                },
                {
                    id: "setupNet", title: "NetworkManager",
                    sub: "Networking · Wi-Fi and Ethernet",
                    glyph: Icons.wifi, keys: "networkmanager nmcli wifi ethernet internet",
                    hint: "browse", check: "command -v nmcli >/dev/null",
                    run: { type: "enterSection", id: "dev-network" }
                },
                {
                    id: "setupShot", title: "Screenshot",
                    sub: "Utilities · select an area with grim + slurp",
                    glyph: g(0xF0100), keys: "screenshot capture screen grim slurp",  // md-camera
                    hint: "cmd", check: "command -v grim >/dev/null && command -v slurp >/dev/null",
                    run: { type: "shell", cmd: "mkdir -p \"$HOME/Pictures/Screenshots\" && grim -g \"$(slurp)\" \"$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png\"" }
                },
                {
                    id: "setupClip", title: "Clipboard history",
                    sub: "Utilities · copy and paste manager",
                    glyph: Icons.clipboard, keys: "clipboard copy paste history cliphist",
                    hint: "browse", run: { type: "enterSection", id: "sys-clipboard" }
                },
                {
                    id: "setupNotif", title: "Notifications",
                    sub: "Utilities · Do Not Disturb and history",
                    glyph: Icons.bell, keys: "notifications dnd alerts",
                    hint: "browse", run: { type: "enterSection", id: "sys-notifications" }
                },
                // Backup
                {
                    id: "setupBackup", title: "Backup configs",
                    sub: "Backup · archive dotfiles to ~/Backups",
                    glyph: g(0xF003C), keys: "backup archive dotfiles configs",  // md-archive
                    hint: "terminal",
                    run: { type: "terminal", cmd: "mkdir -p \"$HOME/Backups\"; tar -czf \"$HOME/Backups/configs-$(date +%Y%m%d).tar.gz\" -C \"$HOME\" .config .local/bin 2>/dev/null; echo 'Backup done:'; ls -lh \"$HOME/Backups\" | tail -n +2; exec bash" }
                },
                {
                    id: "setupRestore", title: "Restore configs",
                    sub: "Backup · extract an archive over ~/  (overwrites files)",
                    glyph: g(0xF1259), keys: "restore recover backup configs",  // md-archive_arrow_down
                    hint: "terminal", danger: true,
                    run: { type: "terminal", cmd: "ls -1 \"$HOME/Backups\"/*.tar.gz 2>/dev/null; read -rp 'Archive name: ' f; [ -n \"$f\" ] && tar -xzf \"$HOME/Backups/$f\" -C \"$HOME\"; exec bash" }
                }
            ]
        },

        // ── 04 Containers ────────────────────────────────────────────
        {
            id: "containers", num: "04", label: "Containers",
            sub: "Distrobox environments and GUI apps",
            glyph: g(0xF4B7),                                    // oct-container
            keys: "distrobox podman docker container linux environment",
            items: [
                {
                    id: "boxList", title: "List containers",
                    sub: "Distrobox · names, images and status",
                    glyph: g(0xF4B7), keys: "list show containers distrobox",
                    hint: "terminal", check: "command -v distrobox >/dev/null",
                    run: { type: "terminal", cmd: "distrobox list; exec bash" }
                },
                {
                    id: "boxCreate", title: "Create a container",
                    sub: "Distrobox · interactive create wizard",
                    glyph: g(0xF0416), keys: "create new container distrobox",  // md-plus_box
                    hint: "terminal", danger: true, check: "command -v distrobox >/dev/null",
                    run: { type: "terminal", cmd: "read -rp 'Name [ubuntu]: ' n; n=${n:-ubuntu}; read -rp 'Image [ubuntu:latest]: ' i; i=${i:-ubuntu:latest}; distrobox create --name \"$n\" --image \"$i\"; exec bash" }
                },
                {
                    id: "boxPrune", title: "Prune unused images",
                    sub: "Podman · remove dangling container images",
                    glyph: g(0xF01B4), keys: "clean prune images cache podman",
                    hint: "terminal", danger: true, check: "command -v podman >/dev/null",
                    run: { type: "terminal", cmd: "podman image prune -f; exec bash" }
                },
                {
                    id: "boxDocs", title: "Container help",
                    sub: "Distrobox · command reference",
                    glyph: g(0xF05DD), keys: "help docs usage distrobox",  // md-bullseye
                    hint: "terminal", check: "command -v distrobox >/dev/null",
                    run: { type: "terminal", cmd: "distrobox --help; exec bash" }
                }
            ]
        },

        // ── 05 Packages ──────────────────────────────────────────────
        {
            id: "packages", num: "05", label: "Packages",
            sub: "Install, remove and update software",
            glyph: g(0xF03D3),                                   // md-package
            keys: "pacman flatpak aur install remove update software",
            items: [
                {
                    id: "pkgInstall", title: "Install package",
                    sub: "fzpac  ·  fuzzy search repos and install selected",
                    glyph: g(0xF03D4), keys: "install add get package pacman fzf",  // md-package_down
                    hint: "fzpac", danger: true, check: "command -v pacman >/dev/null",
                    run: { type: "tui", mode: "S" }
                },
                {
                    id: "pkgRemove", title: "Remove package",
                    sub: "fzpac  ·  fuzzy search installed packages and remove",
                    glyph: g(0xF03D5), keys: "remove uninstall delete package pacman fzf",  // md-package_up
                    hint: "fzpac", danger: true, check: "command -v pacman >/dev/null",
                    run: { type: "tui", mode: "R" }
                },
                {
                    id: "pkgUpdate", title: "Update system",
                    sub: "pacman -Syu  ·  full system upgrade",
                    glyph: g(0xF0450), keys: "update upgrade system pacman syu",
                    hint: "terminal", danger: true, check: "command -v pacman >/dev/null",
                    run: { type: "terminal", cmd: "sudo pacman -Syu; exec bash" }
                },
                {
                    id: "pkgSearch", title: "Search repositories",
                    sub: "fzpac  ·  fuzzy search with package info preview",
                    glyph: g(0xF0349), keys: "search find repos package pacman fzf",  // md-magnify
                    hint: "fzpac", check: "command -v pacman >/dev/null",
                    run: { type: "tui", mode: "s" }
                },
                {
                    id: "pkgInfo", title: "Package details",
                    sub: "fzpac  ·  inspect installed packages",
                    glyph: g(0xF02FD), keys: "info details version package pacman fzf",  // md-information
                    hint: "fzpac", check: "command -v pacman >/dev/null",
                    run: { type: "tui", mode: "l" }
                },
                {
                    id: "pkgHistory", title: "Package history",
                    sub: "/var/log/pacman.log  ·  last 200 lines",
                    glyph: g(0xF02DA), keys: "history log previous operations pacman",  // md-history
                    hint: "terminal", check: "test -r /var/log/pacman.log",
                    run: { type: "terminal", cmd: "tail -n 200 /var/log/pacman.log | less; exec bash" }
                },
                {
                    id: "pkgOrphans", title: "Remove orphans",
                    sub: "fzpac  ·  select unused dependencies to remove",
                    glyph: g(0xF05B7), keys: "orphans unused dependencies clean pacman fzf",  // md-wrench
                    hint: "fzpac", danger: true, check: "command -v pacman >/dev/null",
                    run: { type: "tui", mode: "A" }
                },
                {
                    id: "pkgCache", title: "Clean package cache",
                    sub: "pacman -Sc  ·  remove old archives",
                    glyph: g(0xF01B4), keys: "cache clean prune pacman disk",
                    hint: "terminal", danger: true, check: "command -v pacman >/dev/null",
                    run: { type: "terminal", cmd: "sudo pacman -Sc; exec bash" }
                },
                {
                    id: "flatUpdate", title: "Flatpak update",
                    sub: "flatpak update  ·  refresh all Flatpaks",
                    glyph: g(0xF324), keys: "flatpak update upgrade",  // linux-flathub
                    hint: "terminal", danger: true, check: "command -v flatpak >/dev/null",
                    run: { type: "terminal", cmd: "flatpak update; exec bash" }
                },
                {
                    id: "flatList", title: "List Flatpaks",
                    sub: "flatpak list  ·  installed applications",
                    glyph: g(0xF324), keys: "flatpak list installed",
                    hint: "terminal", check: "command -v flatpak >/dev/null",
                    run: { type: "terminal", cmd: "flatpak list --app; exec bash" }
                }
            ]
        },

        // ── 06 System ────────────────────────────────────────────────
        {
            id: "system", num: "06", label: "System",
            sub: "Notifications, clipboard, session and maintenance",
            glyph: g(0xF048B),                                   // md-server
            keys: "system hardware services processes storage logs maintenance notifications clipboard power",
            items: [
                {
                    id: "sysOverview", title: "System overview",
                    sub: "OS, kernel, uptime, CPU, memory and battery",
                    glyph: Icons.cpu, keys: "overview os kernel uptime hostname telemetry",
                    hint: "browse", run: { type: "enterSection", id: "dev-profile" }
                },
                {
                    id: "sysNotifications", title: "Notifications",
                    sub: "Do Not Disturb and notification history",
                    glyph: Icons.bell, keys: "notifications dnd alerts history",
                    hint: "browse", run: { type: "enterSection", id: "sys-notifications" }
                },
                {
                    id: "sysClipboardMenu", title: "Clipboard history",
                    sub: "Copy again, or clear the cliphist history",
                    glyph: Icons.clipboard, keys: "clipboard copy paste history cliphist",
                    hint: "browse", run: { type: "enterSection", id: "sys-clipboard" }
                },
                {
                    id: "sysKeybinds", title: "Keybinds",
                    sub: "Every active Hyprland shortcut",
                    glyph: Icons.keyboard, keys: "keybinds shortcuts keys hotkeys",
                    hint: "browse", run: { type: "enterSection", id: "sys-keybinds" }
                },
                {
                    id: "sysPowerMenu", title: "Power and session",
                    sub: "Battery, power profiles, lock, suspend, restart",
                    glyph: Icons.power, keys: "power battery profile lock suspend logout reboot shutdown",
                    hint: "browse", run: { type: "enterSection", id: "sys-power" }
                },
                {
                    id: "sysInfo", title: "Hardware info",
                    sub: "fastfetch  ·  CPU, GPU, RAM, disks",
                    glyph: g(0xF0EE0), keys: "hardware cpu gpu ram memory disks fastfetch",  // md-cpu_64_bit
                    hint: "terminal", check: "command -v fastfetch >/dev/null",
                    run: { type: "terminal", cmd: "fastfetch; exec bash" }
                },
                {
                    id: "sysProcesses", title: "Processes",
                    sub: "htop  ·  running processes and load",
                    glyph: g(0xF07B1), keys: "processes tasks htop top load monitor",  // md-chart_line_variant
                    hint: "terminal", check: "command -v htop >/dev/null",
                    run: { type: "terminal", cmd: "htop" }
                },
                {
                    id: "sysServices", title: "Services",
                    sub: "systemctl --user  ·  list and manage units",
                    glyph: g(0xF1460), keys: "services systemd systemctl units start stop enable",
                    hint: "terminal", check: "command -v systemctl >/dev/null",
                    run: { type: "terminal", cmd: "systemctl --user list-units --type=service --no-pager | less; exec bash" }
                },
                {
                    id: "sysStorage", title: "Disk usage",
                    sub: "df -h  ·  filesystem usage and mounts",
                    glyph: g(0xF02CA), keys: "storage disk usage mounts df space",  // md-harddisk
                    hint: "terminal", run: { type: "terminal", cmd: "df -h; echo; lsblk -o NAME,SIZE,TYPE,MOUNTPOINT; exec bash" }
                },
                {
                    id: "sysLogs", title: "System logs",
                    sub: "journalctl  ·  last 200 boot entries",
                    glyph: g(0xF02DA), keys: "logs journal journalctl errors debug",
                    hint: "terminal", check: "command -v journalctl >/dev/null",
                    run: { type: "terminal", cmd: "journalctl -b -n 200 --no-pager | less; exec bash" }
                },
                {
                    id: "sysCache", title: "Cache cleanup",
                    sub: "Remove user caches and thumbnails",
                    glyph: g(0xF05B7), keys: "cleanup cache trash thumbnails maintenance",
                    hint: "terminal", danger: true,
                    run: { type: "terminal", cmd: "echo 'Removing thumbnail caches...'; rm -rf \"$HOME/.cache/thumbnails\" \"$HOME/.cache/quickshell/clipboard\"; echo 'Done.'; exec bash" }
                },
                {
                    id: "sysBackup", title: "Backup configs",
                    sub: "Archive dotfiles to ~/Backups",
                    glyph: g(0xF003C), keys: "backup archive configs dotfiles",
                    hint: "terminal",
                    run: { type: "terminal", cmd: "mkdir -p \"$HOME/Backups\"; tar -czf \"$HOME/Backups/configs-$(date +%Y%m%d).tar.gz\" -C \"$HOME\" .config .local/bin 2>/dev/null; echo 'Backup done.'; exec bash" }
                },
                {
                    id: "sysReboot", title: "Reboot",
                    sub: "Restart the computer now",
                    glyph: Icons.reboot, keys: "reboot restart system power",
                    hint: "power", danger: true,
                    run: { type: "cmd", cmd: ["systemctl", "reboot"] }
                },
                {
                    id: "sysShutdown", title: "Shut down",
                    sub: "Power off the computer now",
                    glyph: Icons.power, keys: "shutdown poweroff off system power",
                    hint: "power", danger: true,
                    run: { type: "cmd", cmd: ["systemctl", "poweroff"] }
                }
            ]
        },

        // ── 07 Style ─────────────────────────────────────────────────
        {
            id: "style", num: "07", label: "Style",
            sub: "Themes, fonts, wallpapers and lock screen",
            glyph: Icons.palette,
            keys: "style colorscheme color scheme wallpaper fonts typography lockscreen appearance",
            items: [
                {
                    id: "styleThemes", title: "Themes",
                    sub: "Colorschemes from ~/.config/kuro/themes",
                    glyph: Icons.palette, keys: "themes colorscheme palette colors",
                    hint: "browse", run: { type: "enterSection", id: "style-themes" }
                },
                {
                    id: "styleFontsMenu", title: "Fonts",
                    sub: "UI and terminal family and size",
                    glyph: "Aa", keys: "fonts typography ui terminal family size",
                    hint: "browse", run: { type: "enterSection", id: "style-fonts" }
                },
                {
                    id: "styleWalls", title: "Wallpapers",
                    sub: "Browse, pick or shuffle your backgrounds",
                    glyph: Icons.image, keys: "wallpapers background image gallery",
                    hint: "browse", run: { type: "enterSection", id: "style-wallpapers" }
                },
                {
                    id: "styleLockscreen", title: "Lockscreen styles",
                    sub: "Lock screen command and configuration",
                    glyph: Icons.lock, keys: "lockscreen lock screen quickshell style",
                    hint: "browse", run: { type: "enterSection", id: "style-lockscreen" }
                },
                {
                    id: "styleAppearance", title: "Appearance",
                    sub: "Gaps, borders, rounding, blur, animations and bar layouts",
                    glyph: Icons.settings, keys: "appearance gaps border rounding blur animations bar layout",
                    hint: "browse", run: { type: "enterSection", id: "style-appearance" }
                },
                {
                    id: "styleKuro", title: "Edit kuro.toml",
                    sub: "Colorschemes, fonts and desktop settings",
                    glyph: g(0xF0DC9), keys: "kuro config edit settings toml theme fonts",
                    hint: "config", check: "test -f \"$HOME/.config/kuro/kuro.toml\"",
                    run: { type: "url", url: "file://" + Config.kuroConfig }
                },
                {
                    id: "styleApply", title: "Apply Kuro settings",
                    sub: "Regenerate Hyprland, kitty and the shell",
                    glyph: g(0xF0450), keys: "apply reload kuro regenerate settings",
                    hint: "instant", keepOpen: true, run: { type: "kuroApply" }
                }
            ]
        },

        // ─────────────────────────────────────────────────────────────
        // Control submenus (rows come from services/LauncherControls.qml)
        // ─────────────────────────────────────────────────────────────
        {
            id: "dev-profile", label: "System profile", hidden: true,
            sub: "Live system information", glyph: Icons.cpu,
            keys: "system profile cpu memory temperature uptime battery host kernel",
            items: []
        },
        {
            id: "dev-network", label: "Network", hidden: true,
            sub: "Wi-Fi and Ethernet", glyph: Icons.wifi,
            keys: "network wifi wireless ethernet nmcli scan connect disconnect",
            items: []
        },
        {
            id: "dev-bluetooth", label: "Bluetooth", hidden: true,
            sub: "Radio and paired devices", glyph: Icons.bluetooth,
            keys: "bluetooth radio pair device connect disconnect",
            items: []
        },
        {
            id: "dev-sound", label: "Sound", hidden: true,
            sub: "Volume, microphone and devices", glyph: Icons.volume,
            keys: "sound audio volume mute speaker microphone mic output input device",
            items: []
        },
        {
            id: "dev-display", label: "Display", hidden: true,
            sub: "Brightness, night light and screens", glyph: Icons.brightness,
            keys: "display brightness night light hyprsunset monitor screen resolution external mirror extend",
            items: []
        },

        // ─────────────────────────────────────────────────────────────
        // System submenus
        // ─────────────────────────────────────────────────────────────
        {
            id: "sys-notifications", label: "Notifications", hidden: true,
            sub: "Do Not Disturb and history", glyph: Icons.bell,
            keys: "notifications dnd do not disturb alerts history clear",
            items: []
        },
        {
            id: "sys-clipboard", label: "Clipboard", hidden: true,
            sub: "Clipboard history", glyph: Icons.clipboard,
            keys: "clipboard copy paste history cliphist",
            items: []
        },
        {
            id: "sys-keybinds", label: "Keybinds", hidden: true,
            sub: "Hyprland shortcuts", glyph: Icons.keyboard,
            keys: "keybinds shortcuts keys hotkeys binds",
            items: []
        },
        {
            id: "sys-power", label: "Power", hidden: true,
            sub: "Battery, profiles and session", glyph: Icons.power,
            keys: "power battery profile lock suspend logout restart shutdown session",
            items: []
        },

        // ─────────────────────────────────────────────────────────────
        // Style submenus
        // ─────────────────────────────────────────────────────────────
        {
            id: "style-themes", label: "Themes", hidden: true,
            sub: "Colorschemes", glyph: Icons.palette,
            keys: "themes colorscheme palette colors",
            items: [
                {
                    id: "themesFolder", title: "Open themes folder",
                    sub: "~/.config/kuro/themes",
                    glyph: Icons.palette, keys: "themes folder files edit toml",
                    hint: "files", check: "test -d \"" + Config.kuroThemesDir + "\"",
                    run: { type: "url", url: "file://" + Config.kuroThemesDir }
                }
            ]
        },
        {
            id: "style-fonts", label: "Fonts", hidden: true,
            sub: "UI and terminal typography", glyph: "Aa",
            keys: "fonts typography ui terminal family size",
            items: [
                {
                    id: "fontUi13", title: "UI size 13", sub: "Smaller shell text",
                    glyph: "Aa", keys: "ui font size 13 small",
                    hint: Config.kuroFonts.uiSize === 13 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "13"] }
                },
                {
                    id: "fontUi14", title: "UI size 14", sub: "Compact shell text",
                    glyph: "Aa", keys: "ui font size 14 compact",
                    hint: Config.kuroFonts.uiSize === 14 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "14"] }
                },
                {
                    id: "fontUi15", title: "UI size 15", sub: "Default shell text",
                    glyph: "Aa", keys: "ui font size 15 default",
                    hint: Config.kuroFonts.uiSize === 15 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "15"] }
                },
                {
                    id: "fontUi16", title: "UI size 16", sub: "Larger shell text",
                    glyph: "Aa", keys: "ui font size 16 large",
                    hint: Config.kuroFonts.uiSize === 16 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "16"] }
                },
                {
                    id: "fontUi17", title: "UI size 17", sub: "Extra large shell text",
                    glyph: "Aa", keys: "ui font size 17 larger",
                    hint: Config.kuroFonts.uiSize === 17 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "17"] }
                },
                {
                    id: "fontUi18", title: "UI size 18", sub: "Largest shell text",
                    glyph: "Aa", keys: "ui font size 18 largest",
                    hint: Config.kuroFonts.uiSize === 18 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.ui_size", "18"] }
                },
                {
                    id: "fontTerm11", title: "Terminal size 11", sub: "kitty font size",
                    glyph: g(0xF489), keys: "terminal font size 11 kitty",
                    hint: Config.kuroFonts.terminalSize === 11 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.terminal_size", "11"] }
                },
                {
                    id: "fontTerm115", title: "Terminal size 11.5", sub: "Default kitty size",
                    glyph: g(0xF489), keys: "terminal font size 11.5 kitty",
                    hint: Config.kuroFonts.terminalSize === 11.5 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.terminal_size", "11.5"] }
                },
                {
                    id: "fontTerm12", title: "Terminal size 12", sub: "Larger kitty text",
                    glyph: g(0xF489), keys: "terminal font size 12 kitty",
                    hint: Config.kuroFonts.terminalSize === 12 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.terminal_size", "12"] }
                },
                {
                    id: "fontTerm125", title: "Terminal size 12.5", sub: "Large kitty text",
                    glyph: g(0xF489), keys: "terminal font size 12.5 kitty",
                    hint: Config.kuroFonts.terminalSize === 12.5 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.terminal_size", "12.5"] }
                },
                {
                    id: "fontTerm13", title: "Terminal size 13", sub: "Largest kitty text",
                    glyph: g(0xF489), keys: "terminal font size 13 kitty",
                    hint: Config.kuroFonts.terminalSize === 13 ? "active" : "apply",
                    run: { type: "cmd", cmd: [Config.kurogen, "set", "fonts.terminal_size", "13"] }
                },
                {
                    id: "fontsEdit", title: "Edit fonts in kuro.toml",
                    sub: "Font families and sizes live in [fonts]",
                    glyph: g(0xF0DC9), keys: "fonts family terminal ui config edit toml",
                    hint: "config", check: "test -f \"$HOME/.config/kuro/kuro.toml\"",
                    run: { type: "url", url: "file://" + Config.kuroConfig }
                },
                {
                    id: "fontsKitty", title: "Terminal appearance",
                    sub: "Generated kitty config  ·  ~/.config/kitty/kuro.conf",
                    glyph: g(0xF489), keys: "kitty terminal appearance colors font config",
                    hint: "config", check: "test -f \"$HOME/.config/kitty/kuro.conf\"",
                    run: { type: "url", url: "file://" + Config.home + "/.config/kitty/kuro.conf" }
                }
            ]
        },
        {
            id: "style-wallpapers", label: "Wallpapers", hidden: true,
            sub: "Background images", glyph: Icons.image,
            keys: "wallpaper background image gallery pick random folder",
            items: []
        },
        {
            id: "style-lockscreen", label: "Lockscreen", hidden: true,
            sub: "Quickshell lock screen and password entry", glyph: Icons.lock,
            keys: "lockscreen lock screen quickshell password pam style",
            items: [
                {
                    id: "lockNow", title: "Lock screen",
                    sub: "Blur the wallpaper and lock this session",
                    glyph: Icons.lock, keys: "lock screen session quickshell pam",
                    hint: "session", check: "command -v qs >/dev/null",
                    run: { type: "cmd", cmd: Config.lockCommand }
                },
                {
                    id: "lockConfig", title: "Edit lock screen UI",
                    sub: "Quickshell/shell/lock/LockScreen.qml",
                    glyph: g(0xF0DC9), keys: "quickshell config lock screen edit qml",
                    hint: "config", check: "test -f \"$HOME/.config/quickshell/shell/lock/LockScreen.qml\"",
                    run: { type: "url", url: "file://" + Config.home + "/.config/quickshell/shell/lock/LockScreen.qml" }
                }
            ]
        },
        {
            id: "style-appearance", label: "Appearance", hidden: true,
            sub: "Hyprland and bar appearance", glyph: Icons.settings,
            keys: "appearance gaps border rounding blur animations bar layout colorscheme",
            items: []
        }
        ];
    }

    // Status probes for the Setup section (installed / missing).
    function checksFor(sectionId) {
        const s = sections.find(x => x.id === sectionId);
        return s ? s.items.filter(i => i.check).map(i => ({ id: i.id, cmd: i.check })) : [];
    }
}
