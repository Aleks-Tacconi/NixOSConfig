import QtQuick
import Quickshell.Io

/**
 * Read transfer rates for the currently preferred network interface.
 */
Item {
    id: root

    required property string interfaceName
    property real downloadBytesPerSecond: 0
    property real uploadBytesPerSecond: 0
    property real previousRxBytes: 0
    property real previousTxBytes: 0
    property real previousTrafficTime: 0

    onInterfaceNameChanged: reset()

    FileView {
        id: rxBytesFile

        path: root.interfaceName.length > 0 ? `/sys/class/net/${root.interfaceName}/statistics/rx_bytes` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: txBytesFile

        path: root.interfaceName.length > 0 ? `/sys/class/net/${root.interfaceName}/statistics/tx_bytes` : ""
        blockAllReads: true
        printErrors: false
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.interfaceName.length > 0
        triggeredOnStart: true
        onTriggered: root.update()
    }

    function reset() {
        root.downloadBytesPerSecond = 0;
        root.uploadBytesPerSecond = 0;
        root.previousRxBytes = 0;
        root.previousTxBytes = 0;
        root.previousTrafficTime = 0;
    }

    function update() {
        rxBytesFile.reload();
        txBytesFile.reload();
        const rxBytes = Number(rxBytesFile.text().trim());
        const txBytes = Number(txBytesFile.text().trim());
        const now = Date.now();
        if (!Number.isFinite(rxBytes) || !Number.isFinite(txBytes))
            return;
        if (root.previousTrafficTime > 0) {
            const elapsed = Math.max(1, (now - root.previousTrafficTime) / 1000);
            root.downloadBytesPerSecond = Math.max(0, (rxBytes - root.previousRxBytes) / elapsed);
            root.uploadBytesPerSecond = Math.max(0, (txBytes - root.previousTxBytes) / elapsed);
        }
        root.previousRxBytes = rxBytes;
        root.previousTxBytes = txBytes;
        root.previousTrafficTime = now;
    }
}
