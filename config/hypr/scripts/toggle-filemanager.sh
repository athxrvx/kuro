#!/bin/sh

app_class="com.thisisgm.flea"
window_address=""

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    window_address=$(hyprctl -j clients 2>/dev/null | jq -r --arg class "$app_class" '[.[] | select(.class == $class or .initialClass == $class)] | first | .address // empty' 2>/dev/null || true)
fi

if [ -n "$window_address" ]; then
    hyprctl dispatch movetoworkspace "special:filemanager,address:$window_address" || exit 1
    hyprctl dispatch togglespecialworkspace filemanager || exit 1
    exit 0
fi

# Create/show the scratch workspace when possible; still launch if IPC lookup fails.
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace filemanager >/dev/null 2>&1 || true
fi
cd "$HOME/.config/kuro/filemanager/target/release" || exit 1
exec ./flea --gui
