pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Bar state: visibility, active layout, and the LAYOUT LIST.
//
// Adding a layout means adding one entry to `layouts`:
//   style  : "solid"   one solid bar (radius + margin = floating bar)
//            "islands" transparent bar, left/center/right become separate "islands"
//            "border"  transparent, each module only has an outline
//   height, radius, margin { top, left, right }, flatTop (only bottom corners rounded)
//   island : true = center is replaced by the dynamic island (island/Island.qml), `center` ignored
//   left / center / right : module lists, see bar/Module.qml
//     workspaces[:kanji|:roman] clock date datetime launcher network bluetooth
//     volume mic brightness battery cpu memory tray notification profile power control clipboard overview weather mouse
Singleton {
    id: root

    property bool shown: Config.barEnabled
    property string current: Config.barLayout

    readonly property var layouts: ({
        "island": {
            style: "islands", height: 32, radius: 16, margin: { top: 6, left: 10, right: 10 }, island: true,
            left:   ["launcher", "workspaces:kanji"],
            center: [],
            right:  ["tray", "network", "volume", "battery", "notification", "control"]
        },
        "omarchy": {
            style: "solid", height: 30, radius: 0, margin: { top: 0, left: 0, right: 0 },
             left: ["workspaces"],
            center: ["clock"],
            right: ["tray", "network", "volume", "mouse", "battery", "control", "power", "notification"]
         },
        "minimal": {
            style: "solid", height: 30, radius: 0, margin: { top: 0, left: 0, right: 0 },
            left:   ["power", "battery", "clock", "workspaces"],
            center: [],
            right:  ["volume", "network", "tray", "notification", "control"]
        },
        "full": {
            style: "islands", height: 34, radius: 10, margin: { top: 8, left: 10, right: 10 },
            left:   ["clock", "power", "network", "bluetooth", "mic"],
            center: ["workspaces", "profile"],
            right:  ["battery", "volume", "brightness", "control"]
        },
        "cozy": {
            style: "islands", height: 32, radius: 12, margin: { top: 6, left: 10, right: 10 },
            left:   ["clock", "battery", "workspaces:kanji"],
            center: [],
            right:  ["tray", "network", "volume", "mic", "notification", "control"]
        },
        "everforest": {
            style: "solid", height: 26, radius: 15, flatTop: true, margin: { top: 0, left: 120, right: 120 },
            left:   ["launcher", "clock", "date"],
            center: ["workspaces"],
            right:  ["volume", "network", "battery", "power", "control"]
        },
        "nest": {
            style: "solid", height: 28, radius: 10, margin: { top: 6, left: 12, right: 12 },
            left:   ["launcher", "workspaces:kanji"],
            center: [],
            right:  ["tray", "network", "volume", "battery", "notification", "control"]
        },
        "hyprnova": {
            style: "solid", height: 30, radius: 8, margin: { top: 3, left: 8, right: 8 },
            left:   ["launcher", "workspaces:roman", "notification", "tray"],
            center: ["clock"],
            right:  ["memory", "battery", "brightness", "volume", "mic", "power", "control"]
        }
    })

    readonly property var names: Object.keys(layouts)
    readonly property var layout: layouts[current] ?? layouts[Config.barLayout] ?? layouts[names[0]]
    readonly property var allModules: layout.left.concat(layout.center, layout.right)

    // Shared clock for all bars
    property alias clock: sysClock
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    function set(name) {
        if (!layouts[name]) return false;
        current = name;
        saveProc.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2"',
                            "sh", name, Config.barStateFile];
        saveProc.running = true;
        return true;
    }

    function next() {
        const i = names.indexOf(current);
        set(names[(i + 1) % names.length]);
    }

    // Restore the last layout at startup
    FileView {
        path: Config.barStateFile
        printErrors: false
        onLoaded: {
            const n = text().trim();
            if (root.layouts[n]) root.current = n;
        }
    }

    Process { id: saveProc }
}
