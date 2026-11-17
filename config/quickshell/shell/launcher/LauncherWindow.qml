// OMNI — an Omarchy-style launcher: six sections, one global search.
// Open: SUPER + SPACE, the launcher button in the bar,
// or  qs -c shell ipc call launcher toggle
//
//   1–6 / TAB       jump / cycle section      ↑ ↓ / Ctrl+J K   move
//   Enter           run (twice for danger)    Esc / outside     close
//   = calc   :clip clipboard   :wall wallpapers   :file files   :win windows
//   > command (background)     ? web search
//
// Search logic lives in services/Launcher.qml. Styling comes from Theme.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services

PanelWindow {
    id: root

    property string query: ""
    property int current: 0
    property int armed: -1                    // dangerous action waiting for a second Enter

    // Hover flyout state (description moved out of the rows to stay minimal).
    property string tipText: ""
    property real tipY: 0

    readonly property var results: Launcher.open ? Launcher.search(query) : []
    readonly property bool browsing: query.trim() === ""
    readonly property var sections: Launcher.sections
    readonly property int rowH: 50
    readonly property bool searching: query.trim() !== ""
    readonly property bool showHeader: Launcher.drilled && !searching
    readonly property string sectionLabel: Launcher.sections.find(s => s.id === Launcher.section)?.label ?? "Menu"
    readonly property int shownRows: Math.max(1, Math.min(results.length, 9))

    // Colors are animated so a palette change fades in.
    property color cBg: Theme.bg
    property color cSurface: Theme.surface
    property color cBorder: Theme.border
    property color cAccent: Theme.accent
    property color cText: Theme.text
    property color cDim: Theme.muted
    Behavior on cBg { ColorAnimation { duration: 300 } }
    Behavior on cAccent { ColorAnimation { duration: 300 } }
    Behavior on cText { ColorAnimation { duration: 300 } }
    Behavior on cDim { ColorAnimation { duration: 300 } }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Launcher.open || panel.opacity > 0

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function resetSelection() { current = 0; armed = -1; hideTip(); }

    function showTip(row) {
        const s = row.result.sub ?? "";
        if (s === "") { tipText = ""; return; }
        tipY = panel.y + row.mapToItem(panel, 0, row.height / 2).y;
        tipText = s;
    }
    function hideTip() { tipText = ""; }

    function selectSection(id) {
        field.text = "";
        root.query = "";
        root.resetSelection();
        Launcher.enterSection(id);
        field.forceActiveFocus();
    }

    function move(d) {
        if (results.length === 0) return;
        current = (current + d + results.length) % results.length;
        armed = -1;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function activate(i) {
        const r = results[i];
        if (!r) return;
        if (r.danger && armed !== i) { armed = i; return; }
        Launcher.run(r);
    }

    Connections {
        target: Launcher
        function onSectionChanged() { root.resetSelection(); }
        function onDrilledChanged() { root.resetSelection(); }
        function onOpenChanged() {
            if (!Launcher.open) { root.hideTip(); return; }
            field.text = "";
            root.query = "";
            root.resetSelection();
            Wallpaper.refresh();
            field.forceActiveFocus();
        }
    }

    onQueryChanged: {
        resetSelection();
        if (query.startsWith(":clip") && Clipboard.items.length === 0) Clipboard.refresh();
        if (query.startsWith(":file")) Launcher.findFiles(query.slice(5));
    }

    onResultsChanged: if (current >= results.length) resetSelection()

    // Click anywhere outside the panel to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.open = false
    }

    Rectangle {
        id: panel
        width: Math.min(300, root.width - 80)
        height: Math.min(root.height - 80, (root.showHeader ? 113 : 83) + root.shownRows * root.rowH)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Centered using the default menu height, then kept fixed so the
        // panel grows downward instead of jumping when the height changes.
        anchors.topMargin: Math.max(56, Math.round((root.height - (83 + Launcher.rootSections.length * root.rowH)) / 2) - 48)
        color: root.cBg
        border.width: 1
        border.color: root.cBorder

        opacity: Launcher.open ? 1 : 0
        scale: Launcher.open ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Search line ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                color: root.cSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: Icons.search
                        color: root.cAccent
                        font.family: Theme.font
                        font.pixelSize: 17
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: field
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.cText
                            selectionColor: Theme.selectionBg
                            selectedTextColor: Theme.selectionFg
                            cursorDelegate: Rectangle { width: 2; color: root.cAccent }
                            font.family: Theme.font
                            font.pixelSize: 17
                            clip: true
                            focus: Launcher.open
                            onTextChanged: root.query = text

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                if (event.key === Qt.Key_Escape) {
                                    if (text !== "") text = "";
                                    else if (Launcher.drilled) Launcher.goBack();
                                    else Launcher.open = false;
                                } else if (event.key === Qt.Key_Left && text === "" && Launcher.drilled) {
                                    Launcher.goBack();
                                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
                                    root.selectSection(Launcher.sections[event.key - Qt.Key_1].id);
                                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    root.selectSection(Launcher.sections[
                                        (Launcher.sections.findIndex(s => s.id === Launcher.section)
                                         + (event.key === Qt.Key_Tab ? 1 : -1) + Launcher.sections.length)
                                        % Launcher.sections.length].id);
                                } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                                    root.move(1);
                                } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                                    root.move(-1);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activate(root.current);
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: field.text === ""
                            text: "Go..."
                            color: root.cDim
                            font.family: Theme.font
                            font.pixelSize: 17
                        }
                    }
                }
            }

            // ── Nested-menu header (back + current category) ────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.showHeader

                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    color: backMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.06)
                                                   : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: Icons.g(0xF0141)                    // md-chevron_left
                        color: root.cText
                        font.family: Theme.font
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Launcher.goBack()
                    }
                }

                Text {
                    text: root.sectionLabel
                    color: root.cAccent
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }
            }

            // ── Divider ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.cBorder
            }

            // ── Results ──────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: root.query.startsWith(":file") && root.query.length < 8 ? "Type at least 4 letters"
                          : "No matches"
                    color: root.cDim
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    model: root.results
                    currentIndex: root.current
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 100
                    highlightResizeDuration: 0

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === root.current
                        readonly property var result: row.modelData

                        width: ListView.view.width
                        height: root.rowH

                        Rectangle {
                            anchors.fill: parent
                            color: row.isCurrent
                                   ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.12)
                                   : rowMouse.containsMouse
                                     ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.04)
                                     : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // Icon (desktop entry / thumbnail / glyph)
                            Item {
                                implicitWidth: 18
                                implicitHeight: 18

                                ClippingRectangle {
                                    anchors.fill: parent
                                    visible: img.status === Image.Ready
                                    color: "transparent"
                                    Image {
                                        id: img
                                        anchors.fill: parent
                                        source: row.result.icon ?? ""
                                        fillMode: row.result.kind === "wall" || row.result.kind === "clip"
                                                  ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        sourceSize.width: 36
                                        sourceSize.height: 36
                                        asynchronous: true
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: img.status !== Image.Ready
                                    text: row.result.glyph ?? ""
                                    color: row.isCurrent ? root.cAccent : row.result.danger ? Theme.danger : root.cDim
                                    font.family: Theme.font
                                    font.pixelSize: 17
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: root.armed === row.index
                                      ? "Press Enter again to " + row.result.title.toLowerCase()
                                      : row.result.title
                                color: root.armed === row.index ? Theme.danger : root.cText
                                font.family: Theme.font
                                font.pixelSize: row.result.kind === "calc" ? 17 : 15
                                elide: Text.ElideRight
                            }

                            // Status / category number / search tag
                            Text {
                                Layout.maximumWidth: 96
                                Layout.alignment: Qt.AlignVCenter
                                text: row.result.status === "missing" ? "missing"
                                      : row.result.status === "ok" ? "installed"
                                      : !root.browsing
                                        ? (row.result.section ? row.result.section + "  " : "")
                                          + (row.result.hint ?? "")
                                        : (row.result.kind === "menu" || row.result.submenu)
                                          ? (row.result.hint ?? "") + "  ›"
                                          : row.result.hint ?? ""
                                color: row.result.status === "missing" ? Theme.danger
                                       : row.result.status === "ok" ? Theme.teal
                                       : root.cDim
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideLeft
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { root.current = row.index; root.armed = -1; root.showTip(row); }
                            onExited: root.hideTip()
                            onClicked: root.activate(row.index)
                        }
                    }
                }
            }
        }
    }

    // ── Hover flyout: the description that used to sit under each row ──
    Rectangle {
        id: tooltip
        visible: root.tipText !== "" && Launcher.open
        x: Math.min(root.width - width - 8, panel.x + panel.width + 8)
        y: root.tipY - height / 2
        width: Math.min(280, Math.max(70, tipLabel.implicitWidth + 18))
        height: 26
        color: root.cSurface
        border.width: 1
        border.color: root.cBorder

        Text {
            id: tipLabel
            anchors.centerIn: parent
            width: parent.width - 16
            text: root.tipText
            color: root.cText
            font.family: Theme.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}
