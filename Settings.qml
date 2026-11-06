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
    spacing: Style.marginL

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

    function loadRunners() {
        if (!pluginApi) return;
        const jsonPath = pluginApi.pluginDir + "/runners.json";
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["cat", "' + jsonPath + '"] }', root, "JsonProc_" + Date.now());
        proc.stdout.connect(function(data) {
            try {
                const parsed = JSON.parse(data.trim());
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
        });
        proc.running = true;
    }

    Component.onCompleted: loadRunners()

    // 1. Runner Pack Selection & Preview Box
    NBox {
        Layout.fillWidth: true
        color: Color.mSurfaceVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            Text {
                text: "Runner Character Selection"
                font.pointSize: Style.fontSizeM
                font.bold: true
                color: Color.mOnSurface
            }

            NComboBox {
                label: "Select Runner (44 Available)"
                description: "Choose from classic cats, animals, mechanisms, or color runners."
                model: root.runnersList
                currentKey: root.editRunner
                onSelected: key => {
                    root.editRunner = key;
                    root.saveSettings();
                    if (pluginApi && pluginApi.mainInstance) {
                        pluginApi.mainInstance.updateRunnerMeta(key);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                Image {
                    width: 64 * Style.uiScaleRatio
                    height: 48 * Style.uiScaleRatio
                    fillMode: Image.PreserveAspectFit
                    source: pluginApi ? pluginApi.pluginDir + "/runners/" + root.editRunner + "/preview.png" : ""
                    cache: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Selected Runner: " + root.editRunner
                        font.pointSize: Style.fontSizeS
                        font.bold: true
                        color: Color.mOnSurface
                    }

                    Text {
                        text: "All community designs are credited to their original creators."
                        font.pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                    }
                }
            }
        }
    }

    // 2. Metrics & Telemetry
    NBox {
        Layout.fillWidth: true
        color: Color.mSurfaceVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            Text {
                text: "Sensor & Reactivity Metrics"
                font.pointSize: Style.fontSizeM
                font.bold: true
                color: Color.mOnSurface
            }

            NComboBox {
                label: "Driving Metric"
                description: "Which system sensor controls the runner's speed."
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
                label: "Audio-Reactive Speed Mode"
                description: "Runner speed pulses to playing music beats via SpectrumService."
                checked: root.editAudioReactive
                onToggled: val => {
                    root.editAudioReactive = val;
                    root.saveSettings();
                }
            }

            NToggle {
                label: "Show Percentage Badge"
                description: "Render metric value (e.g. 38%) directly on the bar capsule."
                checked: root.editShowBadge
                onToggled: val => {
                    root.editShowBadge = val;
                    root.saveSettings();
                }
            }
        }
    }

    // 3. Sleep & Performance Optimization
    NBox {
        Layout.fillWidth: true
        color: Color.mSurfaceVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            Text {
                text: "Sleep Mode (Zero CPU at Idle)"
                font.pointSize: Style.fontSizeM
                font.bold: true
                color: Color.mOnSurface
            }

            NToggle {
                label: "Enable Sleep State"
                description: "Curls up into sleep pose and shuts down animation timer when system is idle."
                checked: root.editSleepEnabled
                onToggled: val => {
                    root.editSleepEnabled = val;
                    root.saveSettings();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Sleep Threshold: " + Math.round(root.editSleepThreshold) + "%"
                    font.pointSize: Style.fontSizeS
                    color: Color.mOnSurface
                    Layout.minimumWidth: 160
                }
                NSlider {
                    Layout.fillWidth: true
                    from: 1.0
                    to: 20.0
                    value: root.editSleepThreshold
                    onMoved: {
                        root.editSleepThreshold = Math.round(value);
                        root.saveSettings();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Turbo / Heat Threshold: " + Math.round(root.editTurboThreshold) + "%"
                    font.pointSize: Style.fontSizeS
                    color: Color.mOnSurface
                    Layout.minimumWidth: 160
                }
                NSlider {
                    Layout.fillWidth: true
                    from: 60.0
                    to: 98.0
                    value: root.editTurboThreshold
                    onMoved: {
                        root.editTurboThreshold = Math.round(value);
                        root.saveSettings();
                    }
                }
            }
        }
    }

    // 4. Appearance & Animation Tuning
    NBox {
        Layout.fillWidth: true
        color: Color.mSurfaceVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            Text {
                text: "Appearance & Sizing"
                font.pointSize: Style.fontSizeM
                font.bold: true
                color: Color.mOnSurface
            }

            NComboBox {
                label: "Color Mode"
                description: "Monochrome runner tinting (Color runners keep natural colors)."
                model: [
                    { key: "default", label: "Theme Default (Surface / Hover)" },
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

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Runner Scale: " + root.editCatScale.toFixed(2) + "x"
                    font.pointSize: Style.fontSizeS
                    color: Color.mOnSurface
                    Layout.minimumWidth: 160
                }
                NSlider {
                    Layout.fillWidth: true
                    from: 0.6
                    to: 1.5
                    value: root.editCatScale
                    onMoved: {
                        root.editCatScale = parseFloat(value.toFixed(2));
                        root.saveSettings();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Speed Multiplier: " + root.editSpeedMultiplier.toFixed(2) + "x"
                    font.pointSize: Style.fontSizeS
                    color: Color.mOnSurface
                    Layout.minimumWidth: 160
                }
                NSlider {
                    Layout.fillWidth: true
                    from: 0.5
                    to: 2.0
                    value: root.editSpeedMultiplier
                    onMoved: {
                        root.editSpeedMultiplier = parseFloat(value.toFixed(2));
                        root.saveSettings();
                    }
                }
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
