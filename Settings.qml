import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    property string editRunner: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.runner) ? pluginApi.pluginSettings.runner : "pixel-cat"
    property string editDriveMetric: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.driveMetric) ? pluginApi.pluginSettings.driveMetric : "cpu"
    property string editCatColor: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catColor) ? pluginApi.pluginSettings.catColor : "default"
    property real editCatScale: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catScale !== undefined) ? pluginApi.pluginSettings.catScale : 1.0
    property real editCatOffsetY: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.catOffsetY !== undefined) ? pluginApi.pluginSettings.catOffsetY : 0.0
    property bool editShowBadge: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.showBadge !== undefined) ? pluginApi.pluginSettings.showBadge : false
    property real editSpeedMultiplier: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.speedMultiplier !== undefined) ? pluginApi.pluginSettings.speedMultiplier : 1.0
    property bool editSleepEnabled: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.sleepEnabled !== undefined) ? pluginApi.pluginSettings.sleepEnabled : true
    property real editSleepThreshold: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.sleepThreshold !== undefined) ? pluginApi.pluginSettings.sleepThreshold : 5.0
    property real editTurboThreshold: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.turboThreshold !== undefined) ? pluginApi.pluginSettings.turboThreshold : 85.0
    property bool editAudioReactive: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.audioReactive !== undefined) ? pluginApi.pluginSettings.audioReactive : false

    property var runnersList: []

    FileView {
        id: runnersJsonView
        path: pluginApi ? (pluginApi.pluginDir + "/runners.json") : ""
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                const model = [];
                for (let i = 0; i < parsed.runners.length; i++) {
                    const r = parsed.runners[i];
                    model.push({
                        key: r.id,
                        label: r.displayName + " (by " + r.author + ")",
                        raw: r
                    });
                }
                root.runnersList = model;
            } catch(e) {}
        }
    }

    implicitWidth: 540 * Style.uiScaleRatio
    implicitHeight: mainLayout.implicitHeight + Style.marginM * 2

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: Style.marginM

        // --- 1. RUNNER SELECTION ---
        NText {
            text: "Runner Character"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mPrimary
        }

        NComboBox {
            label: "Active Runner (44 Templates)"
            description: "Choose an animal, mechanism, or character."
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
                spacing: 2

                NText {
                    text: "Selected: " + root.editRunner
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }

                NText {
                    text: "Community template with full designer attribution in CREDITS.md"
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
            text: "Sensors & Reaction"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mPrimary
        }

        NComboBox {
            label: "Driving Metric"
            description: "System sensor controlling the runner speed."
            model: [
                { key: "cpu", label: "CPU Usage (%)" },
                { key: "mem", label: "RAM Memory Usage (%)" },
                { key: "temp", label: "CPU Temperature (°C)" }
            ]
            currentKey: root.editDriveMetric
            onSelected: key => {
                root.editDriveMetric = key;
                root.saveSettings();
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Audio-Reactive Speed"
            description: "Cat pulses and speeds up to music beats."
            checked: root.editAudioReactive
            onToggled: val => {
                root.editAudioReactive = val;
                root.saveSettings();
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: "Show Percentage Badge"
            description: "Display load percentage (e.g. 28%) next to the runner in the bar."
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
            text: "Idle Sleep & Overheat"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mPrimary
        }

        NToggle {
            Layout.fillWidth: true
            label: "Enable Sleep Mode"
            description: "Halts animation timer completely (0% CPU) when system is idle."
            checked: root.editSleepEnabled
            onToggled: val => {
                root.editSleepEnabled = val;
                root.saveSettings();
            }
        }

        NLabel {
            label: "Sleep Threshold (" + Math.round(root.editSleepThreshold) + "%)"
            description: "Load level below which the runner rests after 12 seconds."
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
            label: "Turbo / Overheat Threshold (" + Math.round(root.editTurboThreshold) + "%)"
            description: "Load level that triggers turbo animation and alert styling."
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

        NDivider {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginS
            Layout.bottomMargin: Style.marginS
        }

        // --- 4. APPEARANCE & SIZING ---
        NText {
            text: "Appearance & Sizing"
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mPrimary
        }

        NComboBox {
            label: "Color Mode"
            description: "White, Primary accent, or Rainbow mode for monochrome runners."
            model: [
                { key: "default", label: "Pure White (Recommended for dark bar)" },
                { key: "primary", label: "Primary Theme Accent" },
                { key: "secondary", label: "Secondary Accent" },
                { key: "error", label: "Alert / Error Red" },
                { key: "rainbow", label: "Rainbow Rave Mode" }
            ]
            currentKey: root.editCatColor
            onSelected: key => {
                root.editCatColor = key;
                root.saveSettings();
            }
        }

        NLabel {
            label: "Runner Scale (" + root.editCatScale.toFixed(2) + "x)"
            description: "Scale runner size up or down to fit your bar."
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
            label: "Speed Multiplier (" + root.editSpeedMultiplier.toFixed(2) + "x)"
            description: "Adjust how quickly the runner reacts to load changes."
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
        pluginApi.saveSettings();
    }
}
