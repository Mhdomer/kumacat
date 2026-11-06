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
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    readonly property var mainInstance: pluginApi ? pluginApi.mainInstance : null

    property bool panelReady: true
    property real contentPreferredWidth: 380 * Style.uiScaleRatio
    property real contentPreferredHeight: 470 * Style.uiScaleRatio

    property var topProcesses: []

    Process {
        id: psProc
        command: ["sh", "-c", "ps -eo comm,%cpu --sort=-%cpu | sed 1d | head -n 3"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const procs = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/);
                    if (parts.length >= 2) {
                        procs.push({
                            name: parts[0],
                            cpu: parts[1] + "%"
                        });
                    }
                }
                root.topProcesses = procs;
                psProc.running = false;
            }
        }
    }

    function refreshTopProcesses() {
        if (!psProc.running) {
            psProc.running = true;
        }
    }

    Component.onCompleted: refreshTopProcesses()

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"
        visible: panelReady

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // 1. Header with Runner Info & Designer Credit
            NBox {
                Layout.fillWidth: true
                color: Color.mSurfaceVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    Image {
                        id: headerPreview
                        width: 48 * Style.uiScaleRatio
                        height: 36 * Style.uiScaleRatio
                        fillMode: Image.PreserveAspectFit
                        source: pluginApi ? pluginApi.pluginDir + "/runners/" + (mainInstance ? mainInstance.runner : "pixel-cat") + "/preview.png" : ""
                        cache: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: mainInstance ? mainInstance.runnerDisplayName : "NoctaCat"
                            font.pointSize: Style.fontSizeL
                            font.bold: true
                            color: Color.mOnSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Designed by: " + (mainInstance ? mainInstance.runnerAuthor : "Takuto Nakamura")
                            font.pointSize: Style.fontSizeXS
                            color: Color.mPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        radius: Style.radiusM
                        color: (mainInstance && mainInstance.isSleeping) ? Color.alpha(Color.mSecondary, 0.2) : ((mainInstance && mainInstance.isTurbo) ? Color.alpha(Color.mError, 0.2) : Color.alpha(Color.mPrimary, 0.2))
                        height: 26 * Style.uiScaleRatio
                        width: statusText.implicitWidth + Style.marginM * 2

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: mainInstance ? (mainInstance.paused ? "Paused" : (mainInstance.isSleeping ? "Sleeping" : (mainInstance.isTurbo ? "Turbo" : "Running"))) : "Running"
                            font.pointSize: Style.fontSizeXS
                            font.bold: true
                            color: (mainInstance && mainInstance.isSleeping) ? Color.mSecondary : ((mainInstance && mainInstance.isTurbo) ? Color.mError : Color.mPrimary)
                        }
                    }
                }
            }

            // 2. Telemetry Gauges Card
            NBox {
                Layout.fillWidth: true
                color: Color.mSurfaceVariant

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    columns: 3
                    rowSpacing: Style.marginS
                    columnSpacing: Style.marginM

                    ColumnLayout {
                        spacing: 2
                        Text { text: "CPU Load"; font.pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        Text {
                            text: (mainInstance ? mainInstance.currentMetricValue : 0) + "%"
                            font.pointSize: Style.fontSizeM; font.bold: true; color: Color.mOnSurface
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text { text: "Frequency"; font.pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        Text {
                            text: SystemStatService.cpuFreq
                            font.pointSize: Style.fontSizeM; font.bold: true; color: Color.mOnSurface
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text { text: "Frame Tick"; font.pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        Text {
                            text: (mainInstance ? mainInstance.frameIntervalMs : 0) + "ms"
                            font.pointSize: Style.fontSizeM; font.bold: true; color: Color.mPrimary
                        }
                    }
                }
            }

            // 3. Process Radar (Top 3 Hogs)
            NBox {
                Layout.fillWidth: true
                color: Color.mSurfaceVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Process Radar (Top CPU)"
                            font.pointSize: Style.fontSizeS
                            font.bold: true
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NButton {
                            text: "Refresh"
                            onClicked: root.refreshTopProcesses()
                        }
                    }

                    Repeater {
                        model: root.topProcesses
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true

                            Text {
                                text: modelData.name
                                font.pointSize: Style.fontSizeS
                                font.family: Style.fontFamilyMonospace
                                color: Color.mOnSurface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.cpu
                                font.pointSize: Style.fontSizeS
                                font.family: Style.fontFamilyMonospace
                                font.bold: true
                                color: Color.mPrimary
                            }
                        }
                    }
                }
            }

            // 4. Quick Switcher
            Text {
                text: "Quick Switch Runner"
                font.pointSize: Style.fontSizeS
                font.bold: true
                color: Color.mOnSurface
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                readonly property var quickRunners: [
                    { id: "pixel-cat", name: "Pixel Cat" },
                    { id: "classic-cat", name: "Classic" },
                    { id: "swift-bird", name: "Bird" },
                    { id: "rubber-duck", name: "Duck" },
                    { id: "frog", name: "Frog" }
                ]

                Repeater {
                    model: parent.quickRunners
                    delegate: NButton {
                        required property var modelData
                        text: modelData.name
                        highlighted: Boolean(mainInstance && mainInstance.runner === modelData.id)
                        Layout.fillWidth: true
                        onClicked: {
                            if (pluginApi) {
                                pluginApi.pluginSettings.runner = modelData.id;
                                pluginApi.saveSettings();
                                if (mainInstance) mainInstance.applyRunnerMeta(modelData.id);
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // 5. Bottom Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: (mainInstance && mainInstance.paused) ? "Resume" : "Pause / Nap"
                    icon: (mainInstance && mainInstance.paused) ? "player-play" : "player-pause"
                    Layout.fillWidth: true
                    onClicked: {
                        if (mainInstance) mainInstance.paused = !mainInstance.paused;
                    }
                }

                NButton {
                    text: "All Runners & Settings"
                    icon: "settings"
                    Layout.fillWidth: true
                    onClicked: {
                        if (pluginApi) {
                            BarService.openPluginSettings(null, pluginApi.manifest);
                        }
                    }
                }
            }
        }
    }
}
