#!/usr/bin/env bash
set -euo pipefail

bundle_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_source="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$bundle_dir/config" "$bundle_dir/home" "$bundle_dir/local/bin"

# Remove only bundle entries that no longer have a matching source. Git records
# these removals so the refreshed tree stays reviewable and uploadable.
while IFS= read -r -d '' tracked; do
    source_path=''
    case "$tracked" in
        config/*)
            rel="${tracked#config/}"
            case "$rel" in
                gtk-4.0/assets|gtk-4.0/gtk.css|gtk-4.0/gtk-dark.css|opencode/service.json|kuro/filemanager|kuro/filemanager/*) source_path='excluded' ;;
                zsh/cache/*) [[ "$rel" == zsh/cache/.keep ]] && source_path="$config_source/$rel" || source_path='excluded' ;;
                *) source_path="$config_source/$rel" ;;
            esac
            ;;
        home/*) source_path="$HOME/${tracked#home/}" ;;
        themes/*) source_path="$HOME/.local/share/themes/${tracked#themes/}" ;;
        local/bin/*)
            name="${tracked#local/bin/}"
            case "$name" in
                fzf) source_path="$bundle_dir/local/bin/fzf" ;;
                mise) source_path='excluded' ;;
                *) source_path="$HOME/.local/bin/$name" ;;
            esac
            ;;
    esac
    if [[ -z "$source_path" || "$source_path" == excluded || ( ! -e "$source_path" && ! -L "$source_path" ) ]]; then
        git -C "$bundle_dir" rm -q -f -- "$tracked"
    fi
done < <(git -C "$bundle_dir" ls-files -z -- config home local/bin themes)

copy_config_tree() {
    local source="$1" destination="$2"
    mkdir -p "$destination"
    tar -C "$source" \
        --exclude='.git' --exclude='*/.git' \
        --exclude='.codex' --exclude='*/.codex' \
        --exclude='.agents' --exclude='*/.agents' \
        --exclude='.aws' --exclude='*/.aws' \
        -cf - . | tar -C "$destination" -xf -
    find "$destination" -type d \( -name .git -o -name .codex -o -name .agents -o -name .aws \) -prune -exec rm -rf -- {} +
}

for source in "$config_source"/*; do
    [[ -e "$source" || -L "$source" ]] || continue
    name="${source##*/}"
    case "$name" in
        Codex|mozilla|pulse) continue ;;
        opencode)
            destination="$bundle_dir/config/opencode"
            mkdir -p "$destination"
            for entry in "$source"/*; do
                [[ -e "$entry" || -L "$entry" ]] || continue
                [[ "${entry##*/}" == service.json ]] && continue
                cp -a -- "$entry" "$destination/"
            done
            continue
            ;;
    esac
    if [[ "$name" == kuro ]]; then
        destination="$bundle_dir/config/kuro"
        mkdir -p "$destination"
        for entry in "$source"/*; do
            [[ -e "$entry" || -L "$entry" ]] || continue
            [[ "${entry##*/}" == filemanager ]] && continue
            if [[ -d "$entry" ]]; then copy_config_tree "$entry" "$destination/${entry##*/}"
            else cp -a -- "$entry" "$destination/"
            fi
        done
    elif [[ "$name" == gtk-4.0 && -d "$source" ]]; then
        mkdir -p "$bundle_dir/config/gtk-4.0"
        [[ -f "$source/settings.ini" ]] && cp -a -- "$source/settings.ini" "$bundle_dir/config/gtk-4.0/"
    elif [[ "$name" == zsh && -d "$source" ]]; then
        destination="$bundle_dir/config/zsh"
        mkdir -p "$destination"
        for entry in "$source"/*; do
            [[ -e "$entry" || -L "$entry" ]] || continue
            [[ "${entry##*/}" == cache ]] && continue
            if [[ -d "$entry" ]]; then copy_config_tree "$entry" "$destination/${entry##*/}"
            else cp -a -- "$entry" "$destination/"
            fi
        done
        mkdir -p "$destination/cache"
        [[ -f "$source/cache/.keep" ]] && cp -a -- "$source/cache/.keep" "$destination/cache/.keep"
    elif [[ -d "$source" ]]; then
        copy_config_tree "$source" "$bundle_dir/config/$name"
    else
        cp -a -- "$source" "$bundle_dir/config/"
    fi
done

theme_source="$HOME/.local/share/themes/Orchis-Dark"
if [[ -d "$theme_source/gtk-3.0" && -d "$theme_source/gtk-4.0" ]]; then
    theme_destination="$bundle_dir/themes/Orchis-Dark"
    mkdir -p "$theme_destination"
    for name in COPYING index.theme; do
        [[ -f "$theme_source/$name" ]] && cp -a -- "$theme_source/$name" "$theme_destination/"
    done
    for name in gtk-2.0 gtk-3.0 gtk-4.0; do
        rm -rf -- "$theme_destination/$name"
        cp -a -- "$theme_source/$name" "$theme_destination/$name"
    done
fi

for name in .zshrc .zshenv .gtkrc-2.0; do
    if [[ -f "$HOME/$name" ]]; then cp -a -- "$HOME/$name" "$bundle_dir/home/$name"; fi
done
# Avoid a source-machine-specific mise activation in portable shell startup.
if [[ -f "$bundle_dir/home/.zshrc" ]]; then
    sed -i '\|mise activate zsh|d' "$bundle_dir/home/.zshrc"
    sed -i "s|/home/atharva/.opencode/bin|\$HOME/.opencode/bin|g" "$bundle_dir/home/.zshrc"
fi
if [[ -f "$bundle_dir/home/.gtkrc-2.0" ]]; then
    sed -i '\|gtkrc-2.0.mine|d' "$bundle_dir/home/.gtkrc-2.0"
fi

if [[ -d "$HOME/.local/bin" ]]; then
    for source in "$HOME/.local/bin"/*; do
        [[ -e "$source" || -L "$source" ]] || continue
        name="${source##*/}"
        case "$name" in fzf|mise) continue ;; esac
        cp -a -- "$source" "$bundle_dir/local/bin/"
    done
fi

chmod +x "$bundle_dir/installer-dots" "$bundle_dir/installer-deps" "$bundle_dir/refresh-bundle.sh"
git -C "$bundle_dir" add -A -- config home local/bin themes
# Keep user-specific locations and service credentials out of the portable snapshot.
if [[ -f "$bundle_dir/config/opencode/service.json" ]]; then git -C "$bundle_dir" rm -q -f -- config/opencode/service.json; fi
if [[ -L "$bundle_dir/config/gtk-4.0/gtk.css" ]]; then git -C "$bundle_dir" rm -q -f -- config/gtk-4.0/gtk.css; fi
if [[ -L "$bundle_dir/config/gtk-4.0/gtk-dark.css" ]]; then git -C "$bundle_dir" rm -q -f -- config/gtk-4.0/gtk-dark.css; fi
if [[ -L "$bundle_dir/config/gtk-4.0/assets" ]]; then git -C "$bundle_dir" rm -q -f -- config/gtk-4.0/assets; fi
echo "Bundle refreshed from $config_source, home Zsh startup files, and custom local scripts."
echo 'Refresh changes are staged for review; no commit or push was made.'
