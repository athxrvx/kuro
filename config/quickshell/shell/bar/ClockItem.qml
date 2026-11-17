// Clock in the bar: left-click opens the calendar, right-click opens clock tools.
//   wheel                    : handled by BarItem (time/date scrolling)

import QtQuick
import qs.config

BarItem {
    id: root

    required property var barWindow
    property string format: "hh:mm"

    // pinned keeps the calendar open until it is clicked again or focus leaves it
    property bool pinned: false

    label: Qt.formatDateTime(BarState.clock.date, format)

    function openCal()  { calendar.visible = true; }
    function closeCal() { calendar.visible = false; pinned = false; }
    function toggleCalendar() {
        if (calendar.visible) closeCal();
        else { pinned = true; openCal(); }
    }

    ClockToolsPopup {
        id: toolsMenu
        barWindow: root.barWindow
        target: root
    }

    onRightClicked: toolsMenu.show()

    CalendarPopup {
        id: calendar
        barWindow: root.barWindow
        target: root
        visible: false

        onDismissed: {
            pinned = false;
            calendar.visible = false;
        }
    }

}
