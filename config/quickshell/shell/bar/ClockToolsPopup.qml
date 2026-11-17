// Clock action menu opened with a right-click.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

PopupWindow {
    id: popup

    required property var barWindow
    required property Item target
    property bool open: false
    property string stage: "actions"
    property string recordArea: "full"

    function place() {
        if (!target || !barWindow) return;
        const p = target.mapToItem(null, target.width / 2, target.height);
        anchor.rect.x = Math.max(4, Math.min(Math.round(p.x - implicitWidth / 2), barWindow.width - implicitWidth - 4));
        anchor.rect.y = Math.round(p.y + Theme.popupGap);
    }

    function show() {
        stage = "actions";
        open = true;
        Qt.callLater(place);
    }

    function showScreenshot() {
        stage = "screenshot-area";
        open = true;
        Qt.callLater(place);
    }

    function showRecording() {
        stage = "record-area";
        open = true;
        Qt.callLater(place);
    }

    function chooseTool(id) {
        switch (id) {
        case "screenshot": stage = "screenshot-area"; break;
        case "color": Capture.pickColor(); open = false; break;
        case "clipboard":
            open = false;
            Qt.callLater(() => Launcher.openNamed("clipboard"));
            break;
        case "record":
            if (Capture.recording) { Capture.stopRecording(); open = false; }
            else stage = "record-area";
            break;
        }
        Qt.callLater(place);
    }

    function takeScreenshot(area) {
        Capture.screenshot(area);
        open = false;
    }

    function chooseRecordArea(area) {
        recordArea = area;
        stage = "record-audio";
        Qt.callLater(place);
    }

    function startRecording(audio) {
        Capture.startRecording(recordArea, audio);
        open = false;
    }

    anchor.window: barWindow
    implicitWidth: stage === "record-audio" ? 600 : 356
    implicitHeight: stage === "actions" ? 214 : stage === "record-audio" ? 120 : 88
    color: "transparent"
    visible: open

    onVisibleChanged: if (visible) place()
    onImplicitWidthChanged: if (visible) Qt.callLater(place)
    onImplicitHeightChanged: if (visible) Qt.callLater(place)

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: popup.open = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            visible: popup.stage === "actions"

            TextButton { Layout.fillWidth: true; text: "Screenshot"; onClicked: popup.chooseTool("screenshot") }
            TextButton { Layout.fillWidth: true; text: "Color picker"; onClicked: popup.chooseTool("color") }
            TextButton { Layout.fillWidth: true; text: "Clipboard"; onClicked: popup.chooseTool("clipboard") }
            TextButton {
                Layout.fillWidth: true
                text: Capture.recording ? "Stop screen recording" : "Screen recording"
                onClicked: popup.chooseTool("record")
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6
            visible: popup.stage !== "actions"

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: popup.stage === "screenshot-area" ? "Screenshot area"
                    : popup.stage === "record-area" ? "Screen recording area"
                    : "Recording audio"
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 11
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: popup.stage === "screenshot-area" || popup.stage === "record-area"

                TextButton {
                    Layout.fillWidth: true
                    text: "Full screen"
                    onClicked: popup.stage === "screenshot-area" ? popup.takeScreenshot("full") : popup.chooseRecordArea("full")
                }
                TextButton {
                    Layout.fillWidth: true
                    text: "Focused window"
                    onClicked: popup.stage === "screenshot-area" ? popup.takeScreenshot("window") : popup.chooseRecordArea("window")
                }
                TextButton {
                    Layout.fillWidth: true
                    text: "Selection"
                    onClicked: popup.stage === "screenshot-area" ? popup.takeScreenshot("selection") : popup.chooseRecordArea("selection")
                }
            }

            Flow {
                Layout.fillWidth: true
                visible: popup.stage === "record-audio"
                spacing: 5

                TextButton { text: "Record with no audio"; onClicked: popup.startRecording("none") }
                TextButton { text: "Record with system audio"; onClicked: popup.startRecording("system") }
                TextButton { text: "Record with external audio"; onClicked: popup.startRecording("external") }
                TextButton { text: "Record with system and external audio"; onClicked: popup.startRecording("both") }
            }
        }
    }
}
