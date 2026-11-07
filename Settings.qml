import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
    property var defaults: (pluginApi && pluginApi.manifest && pluginApi.manifest.metadata && pluginApi.manifest.metadata.defaultSettings) ? pluginApi.manifest.metadata.defaultSettings : ({})

    property string editRunner: cfg.runner ?? defaults.runner ?? "pixel-cat"
    property string editDriveMetric: cfg.driveMetric ?? defaults.driveMetric ?? "cpu"
    property string editCatColor: cfg.catColor ?? defaults.catColor ?? "default"
    property real editCatScale: cfg.catScale ?? defaults.catScale ?? 1.0
    property real editCatOffsetY: cfg.catOffsetY ?? defaults.catOffsetY ?? 0.0
    property bool editShowBadge: cfg.showBadge ?? defaults.showBadge ?? false
    property real editSpeedMultiplier: cfg.speedMultiplier ?? defaults.speedMultiplier ?? 1.0
    property bool editSleepEnabled: cfg.sleepEnabled ?? defaults.sleepEnabled ?? true
    property real editSleepThreshold: cfg.sleepThreshold ?? defaults.sleepThreshold ?? 5.0
    property real editTurboThreshold: cfg.turboThreshold ?? defaults.turboThreshold ?? 85.0
    property bool editAudioReactive: cfg.audioReactive ?? defaults.audioReactive ?? false
    property bool editOnlyPrimaryScreen: cfg.onlyPrimaryScreen ?? defaults.onlyPrimaryScreen ?? false
    property bool editEnableOverheatAlert: cfg.enableOverheatAlert ?? defaults.enableOverheatAlert ?? true

    property var runnersList: []

    function loadRunnersFromRaw(rawList) {
        if (!rawList || !Array.isArray(rawList)) return;
        const model = [];
        for (let i = 0; i < rawList.length; i++) {
            const r = rawList[i];
            model.push({
                key: r.id,
                name: r.displayName + " (" + r.author + ")",
                raw: r
            });
        }
        root.runnersList = model;
    }

    Component.onCompleted: {
        if (pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.runnersList && pluginApi.mainInstance.runnersList.length > 0) {
            root.loadRunnersFromRaw(pluginApi.mainInstance.runnersList);
        }
    }

    FileView {
        id: runnersJsonView
        path: pluginApi ? (pluginApi.pluginDir + "/runners.json") : ""
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                root.loadRunnersFromRaw(parsed.runners || []);
            } catch(e) {}
        }
    }

    spacing: Style.marginM

    // --- 1. RUNNER SELECTION ---
    NText {
        text: pluginApi ? pluginApi.tr("settings.sectionRunner") : "Runner Character"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NComboBox {
        label: pluginApi ? pluginApi.tr("settings.activeRunner.label") : "Active Runner"
        description: pluginApi ? pluginApi.tr("settings.activeRunner.desc") : "Choose an animal, mechanism, or character."
        model: root.runnersList
        currentKey: root.editRunner
        onSelected: key => {
            root.editRunner = key;
            root.saveSettings();
            if (pluginApi && pluginApi.mainInstance) {
                pluginApi.mainInstance.applyRunnerMeta(key);
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Image {
            width: 56 * Style.uiScaleRatio
            height: 42 * Style.uiScaleRatio
            fillMode: Image.PreserveAspectFit
            source: pluginApi ? pluginApi.pluginDir + "/runners/" + root.editRunner + "/preview.png" : ""
            cache: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXXS

            NText {
                text: (pluginApi ? pluginApi.tr("settings.selectedPrefix") : "Selected") + ": " + root.editRunner
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightSemiBold
                color: Color.mOnSurface
            }

            NText {
                text: pluginApi ? pluginApi.tr("settings.templateAttribution") : "Community template with full designer attribution in CREDITS.md"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    // --- 2. METRICS & SENSORS ---
    NText {
        text: pluginApi ? pluginApi.tr("settings.sectionSensors") : "Sensors & Reaction"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NComboBox {
        label: pluginApi ? pluginApi.tr("settings.drivingMetric.label") : "Driving Metric"
        description: pluginApi ? pluginApi.tr("settings.drivingMetric.desc") : "System sensor controlling the runner speed."
        model: [
            { key: "cpu", name: pluginApi ? pluginApi.tr("settings.metric.cpu") : "CPU Usage (%)" },
            { key: "mem", name: pluginApi ? pluginApi.tr("settings.metric.mem") : "RAM Memory Usage (%)" },
            { key: "temp", name: pluginApi ? pluginApi.tr("settings.metric.temp") : "CPU Temperature (°C)" },
            { key: "gpu", name: pluginApi ? pluginApi.tr("settings.metric.gpu") : "GPU Load / Activity (%)" },
            { key: "net", name: pluginApi ? pluginApi.tr("settings.metric.net") : "Network I/O Throughput" }
        ]
        currentKey: root.editDriveMetric
        onSelected: key => {
            root.editDriveMetric = key;
            root.saveSettings();
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi ? pluginApi.tr("settings.audioReactive.label") : "Audio-Reactive Speed"
        description: pluginApi ? pluginApi.tr("settings.audioReactive.desc") : "Cat pulses and speeds up to music beats."
        checked: root.editAudioReactive
        onToggled: val => {
            root.editAudioReactive = val;
            root.saveSettings();
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi ? pluginApi.tr("settings.showBadge.label") : "Show Percentage Badge"
        description: pluginApi ? pluginApi.tr("settings.showBadge.desc") : "Display load percentage next to the runner."
        checked: root.editShowBadge
        onToggled: val => {
            root.editShowBadge = val;
            root.saveSettings();
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    // --- 3. SLEEP & PERFORMANCE ---
    NText {
        text: pluginApi ? pluginApi.tr("settings.sectionSleep") : "Idle Sleep & Overheat"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi ? pluginApi.tr("settings.sleepMode.label") : "Enable Sleep Mode"
        description: pluginApi ? pluginApi.tr("settings.sleepMode.desc") : "Halts animation timer completely (0% CPU) when system is idle."
        checked: root.editSleepEnabled
        onToggled: val => {
            root.editSleepEnabled = val;
            root.saveSettings();
        }
    }

    NLabel {
        label: (pluginApi ? pluginApi.tr("settings.sleepThreshold.label") : "Sleep Threshold") + " (" + Math.round(root.editSleepThreshold) + "%)"
        description: pluginApi ? pluginApi.tr("settings.sleepThreshold.desc") : "Load level below which the runner rests after 12 seconds."
    }

    NSlider {
        Layout.fillWidth: true
        from: 1.0
        to: 20.0
        stepSize: 1.0
        value: root.editSleepThreshold
        onValueChanged: {
            root.editSleepThreshold = Math.round(value);
            root.saveSettings();
        }
    }

    NLabel {
        label: (pluginApi ? pluginApi.tr("settings.turboThreshold.label") : "Turbo / Overheat Threshold") + " (" + Math.round(root.editTurboThreshold) + "%)"
        description: pluginApi ? pluginApi.tr("settings.turboThreshold.desc") : "Load level that triggers turbo animation."
    }

    NSlider {
        Layout.fillWidth: true
        from: 60.0
        to: 98.0
        stepSize: 1.0
        value: root.editTurboThreshold
        onValueChanged: {
            root.editTurboThreshold = Math.round(value);
            root.saveSettings();
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi ? pluginApi.tr("settings.turboAlert.label") : "Sustained Turbo Alert"
        description: pluginApi ? pluginApi.tr("settings.turboAlert.desc") : "Send desktop notification if load stays at turbo threshold for 30s."
        checked: root.editEnableOverheatAlert
        onToggled: val => {
            root.editEnableOverheatAlert = val;
            root.saveSettings();
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    // --- 4. APPEARANCE & SIZING ---
    NText {
        text: pluginApi ? pluginApi.tr("settings.sectionAppearance") : "Appearance & Sizing"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NComboBox {
        label: pluginApi ? pluginApi.tr("settings.colorMode.label") : "Color Mode"
        description: pluginApi ? pluginApi.tr("settings.colorMode.desc") : "White, Primary accent, or Rainbow mode for monochrome runners."
        model: [
            { key: "default", name: pluginApi ? pluginApi.tr("settings.color.white") : "Pure White" },
            { key: "primary", name: pluginApi ? pluginApi.tr("settings.color.primary") : "Primary Theme Accent" },
            { key: "secondary", name: pluginApi ? pluginApi.tr("settings.color.secondary") : "Secondary Accent" },
            { key: "error", name: pluginApi ? pluginApi.tr("settings.color.error") : "Alert / Error Red" },
            { key: "rainbow", name: pluginApi ? pluginApi.tr("settings.color.rainbow") : "Rainbow Rave Mode" }
        ]
        currentKey: root.editCatColor
        onSelected: key => {
            root.editCatColor = key;
            root.saveSettings();
        }
    }

    NLabel {
        label: (pluginApi ? pluginApi.tr("settings.runnerScale.label") : "Runner Scale") + " (" + root.editCatScale.toFixed(2) + "x)"
        description: pluginApi ? pluginApi.tr("settings.runnerScale.desc") : "Scale runner size up or down to fit your bar."
    }

    NSlider {
        Layout.fillWidth: true
        from: 0.6
        to: 1.5
        stepSize: 0.05
        value: root.editCatScale
        onValueChanged: {
            root.editCatScale = parseFloat(value.toFixed(2));
            root.saveSettings();
        }
    }

    NLabel {
        label: (pluginApi ? pluginApi.tr("settings.speedMultiplier.label") : "Speed Multiplier") + " (" + root.editSpeedMultiplier.toFixed(2) + "x)"
        description: pluginApi ? pluginApi.tr("settings.speedMultiplier.desc") : "Adjust how quickly the runner reacts to load changes."
    }

    NSlider {
        Layout.fillWidth: true
        from: 0.5
        to: 2.0
        stepSize: 0.1
        value: root.editSpeedMultiplier
        onValueChanged: {
            root.editSpeedMultiplier = parseFloat(value.toFixed(2));
            root.saveSettings();
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi ? pluginApi.tr("settings.primaryScreenOnly.label") : "Primary Screen Only"
        description: pluginApi ? pluginApi.tr("settings.primaryScreenOnly.desc") : "Show runner only on the primary workstation bar instead of all screens."
        checked: root.editOnlyPrimaryScreen
        onToggled: val => {
            root.editOnlyPrimaryScreen = val;
            root.saveSettings();
        }
    }

    function saveSettings() {
        if (!pluginApi) return;
        pluginApi.pluginSettings.runner = root.editRunner;
        pluginApi.pluginSettings.driveMetric = root.editDriveMetric;
        pluginApi.pluginSettings.catColor = root.editCatColor;
        pluginApi.pluginSettings.catScale = root.editCatScale;
        pluginApi.pluginSettings.catOffsetY = root.editCatOffsetY;
        pluginApi.pluginSettings.showBadge = root.editShowBadge;
        pluginApi.pluginSettings.speedMultiplier = root.editSpeedMultiplier;
        pluginApi.pluginSettings.sleepEnabled = root.editSleepEnabled;
        pluginApi.pluginSettings.sleepThreshold = root.editSleepThreshold;
        pluginApi.pluginSettings.turboThreshold = root.editTurboThreshold;
        pluginApi.pluginSettings.audioReactive = root.editAudioReactive;
        pluginApi.pluginSettings.onlyPrimaryScreen = root.editOnlyPrimaryScreen;
        pluginApi.pluginSettings.enableOverheatAlert = root.editEnableOverheatAlert;
        pluginApi.saveSettings();
    }
}
