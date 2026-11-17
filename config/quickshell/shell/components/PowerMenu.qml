// List of session actions. Edit `actions` to change commands.
// Actions with confirm: true need a second click within `confirmSeconds` seconds.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

ColumnLayout {
    id: root

    signal actionTriggered()

    readonly property int confirmSeconds: 5

    readonly property var actions: [
        { icon: Icons.lock,    label: "Lock",      hint: "quickshell", danger: false, confirm: false,
          cmd: Config.lockCommand },
        { icon: Icons.suspend, label: "Suspend",   hint: "systemctl", danger: false, confirm: false,
          cmd: ["systemctl", "suspend"] },
        { icon: Icons.logout,  label: "Log out",   hint: "hyprctl",   danger: false, confirm: true,
          cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { icon: Icons.reboot,  label: "Restart",   hint: "systemctl", danger: true,  confirm: true,
          cmd: ["systemctl", "reboot"] },
        { icon: Icons.power,   label: "Shut down", hint: "systemctl", danger: true,  confirm: true,
          cmd: ["systemctl", "poweroff"] }
    ]

    // Action awaiting confirmation (-1 = none)
    property int pending: -1
    property int remaining: 0

    function cancel() { pending = -1; countdown.stop(); }

    function trigger(i) {
        const a = actions[i];
        if (a.confirm && pending !== i) {
            pending = i;
            remaining = confirmSeconds;
            countdown.restart();
            return;
        }
        cancel();
        Quickshell.execDetached(a.cmd);
        actionTriggered();
    }

    // Cancel automatically after the countdown, or when the page is left
    onVisibleChanged: if (!visible) cancel()

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0) root.cancel();
        }
    }

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: root.actions

        Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool armed: root.pending === index

            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.radiusSmall
            color: armed ? Theme.danger
                 : mouse.containsMouse ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            readonly property color fg: armed ? Theme.accentFg
                                      : modelData.danger ? Theme.danger : Theme.text

            // Confirmation time remaining bar
            Rectangle {
                visible: row.armed
                anchors.bottom: parent.bottom
                height: 2
                radius: 1
                color: Theme.accentFg
                opacity: 0.5
                width: parent.width * root.remaining / root.confirmSeconds
                Behavior on width { NumberAnimation { duration: 1000 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Text {
                    text: row.modelData.icon
                    color: row.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.iconSize
                }
                Text {
                    Layout.fillWidth: true
                    text: row.armed ? "Click again to " + row.modelData.label.toLowerCase()
                                    : row.modelData.label
                    color: row.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: row.armed
                }
                Text {
                    text: row.armed ? root.remaining + "s · esc to cancel" : row.modelData.hint
                    color: row.armed ? row.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.trigger(row.index)
            }
        }
    }
}
