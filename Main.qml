import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Media
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property string runner: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.runner) ? pluginApi.pluginSettings.runner : "pixel-cat"
    readonly property string driveMetric: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.driveMetric) ? pluginApi.pluginSettings.driveMetric : "cpu"
    readonly property string catColor: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catColor) ? pluginApi.pluginSettings.catColor : "default"
    readonly property real catScale: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catScale !== undefined) ? pluginApi.pluginSettings.catScale : 1.0
    readonly property real catOffsetY: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catOffsetY !== undefined) ? pluginApi.pluginSettings.catOffsetY : 0.0
    readonly property bool showBadge: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.showBadge !== undefined) ? pluginApi.pluginSettings.showBadge : false
    readonly property real speedMultiplier: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.speedMultiplier !== undefined) ? pluginApi.pluginSettings.speedMultiplier : 1.0
    readonly property bool sleepEnabled: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.sleepEnabled !== undefined) ? pluginApi.pluginSettings.sleepEnabled : true
    readonly property real sleepThreshold: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.sleepThreshold !== undefined) ? pluginApi.pluginSettings.sleepThreshold : 5.0
    readonly property real turboThreshold: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.turboThreshold !== undefined) ? pluginApi.pluginSettings.turboThreshold : 85.0
    readonly property bool audioReactive: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.audioReactive !== undefined) ? pluginApi.pluginSettings.audioReactive : false
    readonly property bool onlyPrimaryScreen: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.onlyPrimaryScreen !== undefined) ? pluginApi.pluginSettings.onlyPrimaryScreen : false
    readonly property bool enableOverheatAlert: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.enableOverheatAlert !== undefined) ? pluginApi.pluginSettings.enableOverheatAlert : true

    property real gpuVal: 0
    property bool gpuSysfsAvailable: false
    property int turboSeconds: 0

    property bool paused: false
    property int currentFrame: 0
    property int frameCount: 10
    property bool hasSleepFrame: true
    property string runnerType: "monochrome"
    property string runnerAuthor: "Roy C. Davies (reality2-roycdavies)"
    property string runnerDisplayName: "Pixel Cat (Smooth)"

    property var runnersMap: ({})
    property var runnersList: []

    property bool isSleeping: false
    property bool isTurbo: false
    property int idleSeconds: 0

    readonly property var rainbowPalette: ["#FF5E7E", "#FFAA5A", "#FFEE55", "#55EE88", "#55AAFF", "#AA66FF"]
    property int rainbowIdx: 0
    readonly property string currentRainbowColor: rainbowPalette[rainbowIdx]

    readonly property real cpuVal: SystemStatService.cpuUsage
    readonly property real memVal: SystemStatService.memPercent
    readonly property real tempVal: SystemStatService.cpuTemp
    readonly property bool anyMusic: !SpectrumService.isIdle && MediaService.isPlaying

    readonly property real currentMetricValue: {
        if (audioReactive && anyMusic) {
            const vals = SpectrumService.values;
            if (vals && vals.length > 0) {
                let sum = 0;
                const count = Math.min(6, vals.length);
                for (let i = 0; i < count; i++) sum += vals[i];
                return Math.min(100, Math.round((sum / count) * 100));
            }
        }
        if (driveMetric === "mem") return Math.round(memVal);
        if (driveMetric === "temp") return Math.min(100, Math.max(0, Math.round((tempVal - 30) * 1.5)));
        if (driveMetric === "gpu") {
            if (root.gpuSysfsAvailable) return Math.round(root.gpuVal);
            return Math.min(100, Math.max(0, Math.round((SystemStatService.gpuTemp - 35) * 1.6)));
        }
        if (driveMetric === "net") {
            const kbps = (SystemStatService.rxSpeed + SystemStatService.txSpeed) / 1024;
            if (kbps <= 5) return 0;
            const ratio = Math.min(1.0, Math.log10(kbps / 5) / Math.log10(2048));
            return Math.min(100, Math.max(0, Math.round(ratio * 100)));
        }
        return Math.round(cpuVal);
    }

    FileView {
        id: gpuBusyView
        path: "/sys/class/drm/card2/device/gpu_busy_percent"
        watchChanges: false
        printErrors: false
        onLoaded: {
            const parsed = parseInt(text().trim());
            if (!isNaN(parsed)) {
                root.gpuSysfsAvailable = true;
                root.gpuVal = Math.min(100, Math.max(0, parsed));
            }
        }
    }

    readonly property int frameIntervalMs: {
        const load = Math.min(100, Math.max(0, currentMetricValue));
        const mult = Math.max(0.2, speedMultiplier);
        const base = Math.max(30, Math.round((220 - (load * 1.9)) / mult));
        return Math.min(260, base);
    }

    onCurrentMetricValueChanged: {
        isTurbo = currentMetricValue >= turboThreshold;
        if (!sleepEnabled) {
            isSleeping = false;
            idleSeconds = 0;
            return;
        }
        if (currentMetricValue > sleepThreshold) {
            idleSeconds = 0;
            if (isSleeping) isSleeping = false;
        }
    }

    Timer {
        id: sleepCheckTimer
        interval: 1000
        repeat: true
        running: !root.paused
        onTriggered: {
            if (root.driveMetric === "gpu") {
                gpuBusyView.reload();
            }

            if (root.enableOverheatAlert && root.isTurbo) {
                root.turboSeconds++;
                if (root.turboSeconds === 30) {
                    Quickshell.execDetached([
                        "notify-send",
                        "-a", "KumaCat",
                        "-u", "critical",
                        "KumaCat: Sustained Turbo Load",
                        "High load (" + root.currentMetricValue + "%) detected for 30s. Check Process Radar in the HUD."
                    ]);
                }
            } else {
                root.turboSeconds = 0;
            }

            if (!root.sleepEnabled) return;

            if (root.currentMetricValue <= root.sleepThreshold) {
                root.idleSeconds++;
                if (root.idleSeconds >= 12) {
                    root.isSleeping = true;
                }
            } else {
                root.idleSeconds = 0;
                root.isSleeping = false;
            }
        }
    }

    Timer {
        id: animTimer
        interval: root.frameIntervalMs
        repeat: true
        running: !root.paused && !root.isSleeping && root.frameCount > 0
        onTriggered: {
            root.currentFrame = (root.currentFrame + 1) % root.frameCount;
            if (root.catColor === "rainbow" && (root.currentFrame % 2 === 0)) {
                root.rainbowIdx = (root.rainbowIdx + 1) % root.rainbowPalette.length;
            }
        }
    }

    FileView {
        id: runnersManifestView
        path: pluginApi ? (pluginApi.pluginDir + "/runners.json") : ""
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                const map = {};
                for (let i = 0; i < parsed.runners.length; i++) {
                    map[parsed.runners[i].id] = parsed.runners[i];
                }
                root.runnersMap = map;
                root.runnersList = parsed.runners || [];
                root.applyRunnerMeta(root.runner);
            } catch(e) {}
        }
    }

    function applyRunnerMeta(runnerId) {
        if (!runnersMap[runnerId]) return;
        const r = runnersMap[runnerId];
        root.runnerAuthor = r.author || "Unknown";
        root.runnerDisplayName = r.displayName || runnerId;
        root.runnerType = r.type || "monochrome";
        root.frameCount = r.frameCount || 5;
        root.hasSleepFrame = Boolean(r.hasSleep);
        root.currentFrame = 0;
    }

    onRunnerChanged: applyRunnerMeta(runner)

    IpcHandler {
        target: "plugin:kumacat"

        function pause() { root.paused = true; }
        function resume() { root.paused = false; }
        function toggle() { root.paused = !root.paused; }
        function setRunner(name: string) {
            if (pluginApi) {
                pluginApi.pluginSettings.runner = name;
                pluginApi.saveSettings();
                root.applyRunnerMeta(name);
            }
        }
    }
}
