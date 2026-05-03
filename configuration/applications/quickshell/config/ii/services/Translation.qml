pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property var availableLanguages: ["en_US"]
    property var availableGeneratedLanguages: []
    property bool isScanning: false
    property bool isLoading: false
    property string languageCode: "en_US"

    function tr(text) {
        if (!text) return "";
        return text.toString();
    }
}
