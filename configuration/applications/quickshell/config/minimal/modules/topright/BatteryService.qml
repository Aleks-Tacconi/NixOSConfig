pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/** Shared battery state with a sysfs fallback when UPower has no battery. */
Scope {
    id: root

    property string sysfsBatteryPath: ""
    property bool sysfsBatteryPresent: false
    property int sysfsBatteryPercentValue: 0
    property string sysfsBatteryState: "Unknown"
    property real sysfsBatterySecondsRemainingValue: 0
    property real sysfsBatteryRateWattsValue: 0
    readonly property var laptopBattery: root.laptopBatteryDevice()

    FileView {
        id: batteryPresentFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/present` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryCapacityFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/capacity` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryStatusFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/status` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryPowerNowFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/power_now` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryEnergyNowFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/energy_now` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryEnergyFullFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/energy_full` : ""
        blockAllReads: true
        printErrors: false
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.sysfsBatteryPath.length > 0 && root.laptopBattery === null
        triggeredOnStart: true
        onTriggered: root.updateSysfsBattery()
    }

    Process {
        id: batteryPathProcess

        stdout: StdioCollector {
            id: batteryPathOutput

            onStreamFinished: root.applySysfsBatteryPath(batteryPathOutput.text)
        }
    }

    Component.onCompleted: root.refreshSysfsBatteryPath()
    onSysfsBatteryPathChanged: root.updateSysfsBattery()

    /** Read device values from the UPower model. */
    function modelValues(model) {
        return model?.values ?? [];
    }

    /** Find the present laptop battery. */
    function laptopBatteryDevice() {
        return root.modelValues(UPower.devices).find(device => device.isLaptopBattery && device.isPresent) ?? null;
    }

    /** Discover the fallback battery directory. */
    function refreshSysfsBatteryPath() {
        batteryPathProcess.exec(["sh", "-lc", 'for battery in /sys/class/power_supply/BAT*; do [ -d "$battery" ] || continue; read -r type < "$battery/type" || continue; read -r present < "$battery/present" || continue; [ "$type" = "Battery" ] && [ "$present" = "1" ] && printf "%s" "$battery" && break; done']);
    }

    /** Apply the discovered battery path. */
    function applySysfsBatteryPath(output) {
        root.sysfsBatteryPath = output.trim();
    }

    /** Read a numeric sysfs measurement. */
    function readNumber(file) {
        const value = Number(file.text().trim());

        return Number.isFinite(value) ? value : 0;
    }

    /** Refresh fallback charge and remaining time. */
    function updateSysfsBattery() {
        if (root.sysfsBatteryPath.length === 0)
            return;

        batteryPresentFile.reload();
        batteryCapacityFile.reload();
        batteryStatusFile.reload();
        batteryPowerNowFile.reload();
        batteryEnergyNowFile.reload();
        batteryEnergyFullFile.reload();

        const present = batteryPresentFile.text().trim() === "1";
        const capacity = root.readNumber(batteryCapacityFile);
        const status = batteryStatusFile.text().trim();
        const powerWatts = root.readNumber(batteryPowerNowFile) / 1000000;
        const energyNow = root.readNumber(batteryEnergyNowFile) / 1000000;
        const energyFull = root.readNumber(batteryEnergyFullFile) / 1000000;

        root.sysfsBatteryPresent = present;
        root.sysfsBatteryPercentValue = Math.max(0, Math.min(100, Math.round(capacity)));
        root.sysfsBatteryState = status.length > 0 ? status : "Unknown";
        root.sysfsBatteryRateWattsValue = Math.max(0, powerWatts);

        if (!present || powerWatts <= 0) {
            root.sysfsBatterySecondsRemainingValue = 0;
            return;
        }

        if (status === "Charging" && energyFull > energyNow) {
            root.sysfsBatterySecondsRemainingValue = (energyFull - energyNow) / powerWatts * 3600;
            return;
        }

        if (status === "Discharging" && energyNow > 0) {
            root.sysfsBatterySecondsRemainingValue = energyNow / powerWatts * 3600;
            return;
        }

        root.sysfsBatterySecondsRemainingValue = 0;
    }

}
