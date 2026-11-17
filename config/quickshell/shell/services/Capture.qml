pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Small desktop capture actions used by the clock hover tools.
Singleton {
    id: root

    property bool recording: false

    function screenshot(area) {
        Quickshell.execDetached([Config.captureScript, "screenshot", area]);
    }

    function pickColor() {
        Quickshell.execDetached(["hyprpicker", "-a"]);
    }

    function startRecording(area, audio) {
        if (recording) return;
        recording = true;
        Quickshell.execDetached([Config.captureScript, "record", area, audio]);
    }

    function stopRecording() {
        if (!recording) return;
        Quickshell.execDetached([Config.captureScript, "stop"]);
        recording = false;
    }

    FileView {
        path: Config.captureStateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.recording = text().trim() !== ""
        onLoadFailed: root.recording = false
    }
}
