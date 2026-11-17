// Compact Omarchy-style click popup for a bar module, anchored under the item.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

PopupWindow {
    id: popup

    required property var barWindow
    required property Item target

    readonly property string title: ({
        network: "Network", volume: "Sound", mic: "Microphone",
        brightness: "Brightness", battery: "Battery", power: "Power",
        memory: "Memory", profile: "Power profile", bluetooth: "Bluetooth",
        clipboard: "Clipboard", mouse: "Mouse", window: "Window", tray: "System tray"
    })[BarPopup.kind] ?? BarPopup.kind

    function place() {
        const p = target.mapToItem(null, target.width / 2, target.height);
        const x = Math.round(p.x - implicitWidth / 2);
        anchor.rect.x = Math.max(4, Math.min(x, barWindow.width - implicitWidth - 4));
        anchor.rect.y = Math.round(p.y + Theme.popupGap);
    }

    function componentFor(kind) {
        return ({
            network: networkC, volume: volumeC, mic: micC,
            brightness: brightnessC, battery: batteryC, power: powerC,
            memory: memoryC, profile: profileC, bluetooth: bluetoothC,
            clipboard: clipboardC, mouse: mouseC, window: windowC, tray: trayC
        })[kind] ?? null;
    }

    function refresh() {
        switch (BarPopup.kind) {
            case "network":    Network.refresh(); Network.scan(false); break;
            case "volume":
            case "mic":        Audio.refresh(); break;
            case "brightness": Brightness.refresh(); break;
            case "battery":    Battery.refresh(); break;
            case "memory":     SystemStats.refresh(); break;
            case "profile":    PowerProfile.refresh(); break;
            case "bluetooth":  Bluetooth.refresh(); break;
            case "clipboard":  Clipboard.refresh(); break;
            case "mouse":      MouseBattery.refresh(); break;
        }
    }

    anchor.window: barWindow
    visible: BarPopup.open && BarPopup.kind !== ""
    implicitWidth: 320
    implicitHeight: Math.min(480, body.implicitHeight + 24)
    color: "transparent"

    onVisibleChanged: if (visible) { place(); refresh(); }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible && BarPopup.kind !== "tray"
        onCleared: BarPopup.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.border
        clip: true

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: body.implicitHeight

            ColumnLayout {
                id: body
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: popup.title.toUpperCase()
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.letterSpacing: 1.5
                    }

                    TextButton { radius: 0;
                        text: Icons.close
                        onClicked: BarPopup.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: popup.componentFor(BarPopup.kind)
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 4
                visible: flick.contentHeight > flick.height
                color: "transparent"

                Rectangle {
                    width: 3
                    x: 1
                    height: Math.max(24, flick.height * flick.visibleArea.heightRatio)
                    y: flick.visibleArea.yPosition * flick.height
                    radius: 0
                    color: Theme.border
                }
            }
        }
    }

    Component {
        id: networkC
        ColumnLayout {
            id: networkBody
            property string expanded: ""
            spacing: 8

            ListRow { radius: 0;
                icon: Network.ethConnected ? Icons.ethernet : Icons.wifi
                title: Network.ethConnected ? "Ethernet" : (Network.ssid || "Wi-Fi")
                sub: Network.ethConnected ? Network.ethIp : (Network.wifiIp || "Not connected")
                trailing: Network.online ? "on" : "off"
                active: true
                interactive: false
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { radius: 0;
                    text: Network.enabled ? Icons.wifi + "  Disable Wi-Fi" : Icons.wifiOff + "  Enable Wi-Fi"
                    onClicked: Network.toggle()
                }
                Item { Layout.fillWidth: true }
                TextButton { radius: 0; text: Icons.refresh; onClicked: Network.scan(true) }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: Network.error
                color: Theme.danger
                font.family: Theme.font
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                visible: Network.enabled && Network.networks.length === 0
                text: Network.scanning ? "Scanning for Wi-Fi networks…" : "No networks found. Try scanning again."
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Repeater {
                model: Network.networks
                ListRow {
                    id: row
                    radius: 0
                    required property var modelData
                    readonly property bool open: networkBody.expanded === modelData.ssid
                    readonly property bool needsPassword: modelData.secure && !modelData.known && !modelData.active

                    icon: Icons.wifiStrength[Math.min(4, Math.floor(modelData.signal / 20))]
                    title: modelData.ssid
                    sub: modelData.security + (modelData.known ? "  ·  saved" : "")
                    trailing: Network.connecting === modelData.ssid ? "connecting…"
                            : modelData.active ? "connected" : modelData.signal + "%"
                    active: modelData.active
                    busy: Network.connecting === modelData.ssid
                    onClicked: networkBody.expanded = open ? "" : modelData.ssid

                    RowLayout {
                        visible: row.open
                        Layout.fillWidth: true
                        spacing: 8

                        InputField {
                            id: pw
                            radius: 0
                            visible: row.needsPassword
                            password: true
                            placeholder: "Password"
                            onAccepted: if (text !== "") {
                                Network.connect(row.modelData, text);
                                text = "";
                            }
                            onVisibleChanged: if (visible) forceFocus()
                        }
                        Item { visible: !row.needsPassword; Layout.fillWidth: true }
                        TextButton {
                            radius: 0
                            primary: true
                            text: row.modelData.active ? "Disconnect" : "Connect"
                            enabled: Network.connecting === "" && (!row.needsPassword || pw.text !== "")
                            onClicked: {
                                if (row.modelData.active) Network.disconnect();
                                else {
                                    Network.connect(row.modelData, pw.text);
                                    pw.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: volumeC
        ColumnLayout {
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 0
                to: 100
                value: Math.round(Audio.volume * 100)
                label: "Volume"
                suffix: "%"
                onMoved: v => Audio.setVolume(v / 100)
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { radius: 0;
                    text: Audio.muted ? "Unmute" : "Mute"
                    primary: Audio.muted
                    onClicked: Audio.toggleMute()
                }
                Item { Layout.fillWidth: true }
                Text { text: Math.round(Audio.volume * 100) + "%"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize }
            }

            Repeater {
                model: Audio.sinks
                ListRow { radius: 0;
                    icon: Icons.speaker
                    title: modelData.name
                    sub: modelData.isDefault ? "Default output" : "Output"
                    active: modelData.isDefault
                    onClicked: Audio.setDefault(modelData, true)
                }
            }
        }
    }

    Component {
        id: micC
        ColumnLayout {
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 0
                to: 100
                value: Math.round(Audio.micVolume * 100)
                label: "Microphone"
                suffix: "%"
                onMoved: v => Audio.setMicVolume(v / 100)
            }

            TextButton { radius: 0;
                text: Audio.micMuted ? "Unmute microphone" : "Mute microphone"
                primary: Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }
        }
    }

    Component {
        id: brightnessC
        ColumnLayout {
            spacing: 10

            ValueSlider { trackRadius: 0; handleRadius: 0;
                from: 1
                to: 100
                value: Math.round(Brightness.value * 100)
                label: "Brightness"
                suffix: "%"
                onMoved: v => Brightness.setValue(v / 100)
            }
        }
    }

    Component {
        id: batteryC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Battery.charging ? Icons.charging : Icons.battery
                title: Battery.percent + "%"
                sub: Battery.status || "Battery"
                trailing: Battery.timeLeft
                active: true
                interactive: false
            }

            Text {
                Layout.fillWidth: true
                text: "Power draw: " + Battery.watts.toFixed(1) + " W"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }

            Repeater {
                model: PowerProfile.profiles
                ListRow { radius: 0;
                    icon: modelData === "performance" ? Icons.speed : modelData === "power-saver" ? Icons.leaf : Icons.balance
                    title: PowerProfile.pretty(modelData)
                    active: modelData === PowerProfile.current
                    onClicked: PowerProfile.set(modelData)
                }
            }
        }
    }

    Component {
        id: powerC
        ColumnLayout {
            spacing: 8

            TextButton { radius: 0; text: Icons.lock + "  Lock"; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
            TextButton { radius: 0; text: Icons.suspend + "  Suspend"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
            TextButton { radius: 0; text: Icons.logout + "  Log out"; onClicked: Hyprland.dispatch("exit") }
            TextButton { radius: 0; text: Icons.reboot + "  Reboot"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
            TextButton { radius: 0; text: Icons.power + "  Shut down"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
        }
    }

    Component {
        id: memoryC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Icons.cpu
                title: "CPU " + Math.round(SystemStats.cpu * 100) + "%"
                sub: "Current processor usage"
                active: true
                interactive: false
            }

            ListRow { radius: 0;
                icon: Icons.memory
                title: Math.round(SystemStats.mem * 100) + "% used"
                sub: SystemStats.formatKiB(SystemStats.memUsed) + " / " + SystemStats.formatKiB(SystemStats.memTotal)
                active: true
                interactive: false
            }

            Text {
                Layout.fillWidth: true
                text: "Temperature: " + (SystemStats.temp > 0 ? SystemStats.temp + " °C" : "n/a")
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    Component {
        id: profileC
        ColumnLayout {
            spacing: 8

            Repeater {
                model: PowerProfile.profiles
                ListRow { radius: 0;
                    icon: modelData === "performance" ? Icons.speed : modelData === "power-saver" ? Icons.leaf : Icons.balance
                    title: PowerProfile.pretty(modelData)
                    active: modelData === PowerProfile.current
                    onClicked: PowerProfile.set(modelData)
                }
            }
        }
    }

    Component {
        id: bluetoothC
        ColumnLayout {
            spacing: 8

            TextButton { radius: 0;
                text: Bluetooth.powered ? "Turn Bluetooth off" : "Turn Bluetooth on"
                primary: !Bluetooth.powered
                onClicked: Bluetooth.toggle()
            }

            Repeater {
                model: Bluetooth.devices
                ListRow { radius: 0;
                    icon: Icons.bluetooth
                    title: modelData.name
                    sub: modelData.mac
                    trailing: modelData.connected ? "connected" : ""
                    active: modelData.connected
                    busy: Bluetooth.pending === modelData.mac
                    onClicked: Bluetooth.toggleDevice(modelData)
                }
            }
        }
    }

    Component {
        id: clipboardC
        ColumnLayout {
            spacing: 8

            Repeater {
                model: Clipboard.items.slice(0, 8)
                ListRow { radius: 0;
                    icon: Icons.clipboard
                    title: modelData.image ? (modelData.meta || "Image") : (modelData.text || "Text")
                    sub: modelData.image ? "" : (modelData.text || "")
                    trailing: Clipboard.copied === modelData.id ? Icons.check : ""
                    onClicked: Clipboard.copy(modelData)
                }
            }

            TextButton { radius: 0;
                text: Icons.trash + "  Clear clipboard"
                onClicked: Clipboard.wipe()
            }
        }
    }

    Component {
        id: mouseC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: MouseBattery.charging ? Icons.charging : Icons.battery
                title: MouseBattery.level + "%"
                sub: MouseBattery.asleep ? "Asleep (last known level)" : (MouseBattery.charging ? "Charging" : "Mouse battery")
                active: true
                interactive: false
            }

            TextButton { radius: 0; text: Icons.refresh + "  Refresh"; onClicked: MouseBattery.refresh() }
        }
    }

    Component {
        id: windowC
        ColumnLayout {
            spacing: 8

            ListRow { radius: 0;
                icon: Icons.overview
                title: ToplevelManager.activeToplevel?.title || "No active window"
                sub: ToplevelManager.activeToplevel?.appId || ""
                active: true
                interactive: false
            }

            RowLayout {
                Layout.fillWidth: true
                TextButton { radius: 0; text: "Float"; onClicked: Hyprland.dispatch("togglefloating") }
                TextButton { radius: 0; text: "Fullscreen"; onClicked: Hyprland.dispatch("fullscreen") }
                TextButton { radius: 0; text: Icons.close + "  Close"; primary: true; onClicked: Hyprland.dispatch("closewindow") }
            }
        }
    }

    Component {
        id: trayC
        ColumnLayout {
            spacing: 6

            Repeater {
                id: trayRepeater
                model: SystemTray.items

                Rectangle {
                    id: itemRow
                    required property var modelData
                    readonly property bool hasMenu: !!modelData.hasMenu

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 0
                    color: mouse.containsMouse ? Theme.surface : "transparent"

                    function openMenu() {
                        if (!hasMenu) return;
                        const p = itemRow.mapToItem(null, 0, itemRow.height);
                        menu.anchor.rect.x = p.x;
                        menu.anchor.rect.y = p.y;
                        menu.anchor.rect.width = itemRow.width;
                        menu.anchor.rect.height = 6;
                        menu.open();
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: m => {
                            if (m.button === Qt.RightButton || itemRow.modelData.onlyMenu) itemRow.openMenu();
                            else { itemRow.modelData.activate(); BarPopup.close(); }
                        }
                        onWheel: wheel => {
                            const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                            itemRow.modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                        }
                    }

                    IconImage {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        source: itemRow.modelData.icon
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemRow.modelData.title || itemRow.modelData.id
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }

                    QsMenuAnchor {
                        id: menu
                        menu: itemRow.modelData.menu
                        anchor.window: popup
                        anchor.edges: Edges.Bottom | Edges.Left
                        anchor.gravity: Edges.Bottom | Edges.Right
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: trayRepeater.count === 0
                text: "No tray items"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
