// Unlabeled quick actions placed inline immediately left of the clock.
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    required property var barWindow
    readonly property int buttonSize: 24
    readonly property int gap: 4
    implicitWidth: buttonSize * 4 + gap * 3
    implicitHeight: buttonSize
    opacity: ClockTools.shown ? 1 : 0
    enabled: ClockTools.shown

    HoverHandler {
        onHoveredChanged: hovered ? ClockTools.hold() : ClockTools.scheduleHide()
    }

    function run(action) {
        switch (action) {
        case "screenshot": chooser.showScreenshot(); break;
        case "color": Capture.pickColor(); break;
        case "clipboard": Launcher.openNamed("clipboard"); break;
        case "record":
            if (Capture.recording) Capture.stopRecording();
            else chooser.showRecording();
            break;
        }
    }

    ClockToolsPopup {
        id: chooser
        barWindow: root.barWindow
        target: root
    }

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: [
                { id: "screenshot", icon: Icons.g(0xF0100), tint: Theme.subtext },
                { id: "color", icon: Icons.palette, tint: Theme.subtext },
                { id: "clipboard", icon: Icons.clipboard, tint: Theme.subtext },
                { id: "record", icon: Capture.recording ? "■" : Icons.g(0xF044A),
                  tint: Capture.recording ? Theme.danger : Theme.subtext }
            ]

            delegate: Item {
                id: actionItem
                required property var modelData
                width: root.buttonSize
                height: root.buttonSize

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: actionMouse.containsMouse ? Theme.surface2 : "transparent"
                    border.width: actionMouse.containsMouse ? 1 : 0
                    border.color: Theme.border
                }

                Text {
                    anchors.centerIn: parent
                    text: actionItem.modelData.icon
                    color: actionMouse.containsMouse ? Theme.accent : actionItem.modelData.tint
                    font.family: Theme.font
                    font.pixelSize: 16
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.name: actionItem.modelData.id
                    onEntered: ClockTools.hold()
                    onExited: ClockTools.scheduleHide()
                    onClicked: root.run(actionItem.modelData.id)
                }
            }
        }
    }
}
