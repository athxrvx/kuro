// Month calendar popup with current weather and a short forecast.
// Weeks start on Monday. Scroll / ‹ › buttons change the month, click the title for today.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

PopupWindow {
    id: popup

    required property var barWindow     // bar PanelWindow
    required property Item target       // clock item used as the position reference

    signal dismissed()

    readonly property bool hovered: hover.hovered

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()       // 0..11
    property date selectedDate: today
    property bool showDay: false

    readonly property var dayNames: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                       "July", "August", "September", "October", "November", "December"]

    // 42 cells (6 weeks): { day, current (this month), today }
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7;            // Monday = 0
        const start = new Date(year, month, 1 - offset);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                current: d.getMonth() === month,
                today: d.toDateString() === today.toDateString(),
                date: d
            });
        }
        return out;
    }

    function shift(n) {
        const d = new Date(year, month + n, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    function resetMonth() {
        today = new Date();
        year = today.getFullYear();
        month = today.getMonth();
    }

    function selectDate(d) {
        selectedDate = d;
        showDay = true;
    }

    function place() {
        const p = target.mapToItem(null, target.width / 2, target.height);
        const x = Math.round(p.x - implicitWidth / 2);
        anchor.rect.x = Math.max(4, Math.min(x, barWindow.width - implicitWidth - 4));
        anchor.rect.y = Math.round(p.y + Theme.popupGap);
    }

    anchor.window: barWindow
    readonly property bool showWeather: Config.weatherEnabled && Weather.available
    readonly property var shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]   // getDay(): Sunday = 0

    implicitWidth: Math.max(280, Math.min(340, barWindow.width - 16))
    implicitHeight: body.implicitHeight + 24
    color: "transparent"

    onVisibleChanged: if (visible) {
        resetMonth();
        place();
        if (Config.weatherEnabled && !Weather.available) Weather.refresh();
    }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: popup.dismissed()
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.border

        HoverHandler { id: hover }

        WheelHandler {
            onWheel: event => popup.shift(event.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            // ── Current weather (click icon = refresh) ────────────────
            RowLayout {
                Layout.fillWidth: true
                visible: popup.showWeather
                spacing: 12

                Text {
                    text: Weather.icon
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 42
                    opacity: Weather.loading ? 0.5 : 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Weather.refresh() }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: Math.round(Weather.temp) + "°"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 30
                            font.bold: true
                        }
                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Weather.description
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                            }
                            Text {
                                text: Weather.loading ? "updating…" : Weather.city
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.maximumWidth: 150
                            }
                        }
                    }

                    Text {
                        text: "feels " + Math.round(Weather.feels) + "°   ·   "
                              + Weather.humidity + "%   ·   " + Math.round(Weather.wind) + " km/h"
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
                visible: popup.showWeather
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 440
                    spacing: 10

                    // Title + navigation
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "‹"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: 23
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.shift(-1) }
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: popup.monthNames[popup.month] + " " + popup.year
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                            font.bold: true
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.resetMonth() }
                        }

                        Text {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "›"
                            color: Theme.subtext
                            font.family: Theme.font
                            font.pixelSize: 23
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popup.shift(1) }
                        }
                    }

                    // Day names
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 4

                        Repeater {
                            model: popup.dayNames
                            Text {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: index >= 5 ? Theme.rose : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        // Dates
                        Repeater {
                            model: popup.cells
                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool selected: popup.showDay
                                    && modelData.date.toDateString() === popup.selectedDate.toDateString()

                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 0
                                color: modelData.today ? Theme.accent
                                     : selected ? Theme.surface2 : "transparent"
                                border.width: selected && !modelData.today ? 1 : 0
                                border.color: Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.today ? Theme.accentFg
                                         : !modelData.current ? Theme.muted
                                         : index % 7 >= 5 ? Theme.rose : Theme.text
                                    opacity: modelData.current ? 1 : 0.5
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    font.bold: modelData.today
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.selectDate(modelData.date)
                                }
                            }
                        }
                    }

                    // Full date for the selected day
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(popup.selectedDate, "dddd, d MMMM yyyy")
                        color: Theme.subtext
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

            }

            // ── 5-day forecast ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
                visible: popup.showWeather
            }

            RowLayout {
                Layout.fillWidth: true
                visible: popup.showWeather
                spacing: 8

                Repeater {
                    model: Weather.daily
                    ColumnLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            radius: 0
                            color: index === 0 ? Theme.accent : Theme.surface2
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: index === 0 ? "Today" : popup.shortDays[modelData.date.getDay()]
                            color: index === 0 ? Theme.text : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.bold: index === 0
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Weather.iconFor(modelData.code, true)
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: 21
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Math.round(modelData.max) + "°"
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Math.round(modelData.min) + "°"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: modelData.rain >= 30     // show when rain chance is significant
                            text: modelData.rain + "%"
                            color: Theme.rose
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
