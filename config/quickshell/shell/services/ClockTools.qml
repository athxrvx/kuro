pragma Singleton

import QtQuick
import Quickshell

// Hover handoff between a clock and its inline icon strip.
Singleton {
    id: root

    property bool shown: false

    function reveal() {
        hideTimer.stop();
        shown = true;
    }

    function hold() { hideTimer.stop(); }
    function scheduleHide() { hideTimer.restart(); }

    Timer {
        id: hideTimer
        interval: 350
        onTriggered: root.shown = false
    }
}
