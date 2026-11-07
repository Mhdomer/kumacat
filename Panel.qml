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
    property ShellScreen screen
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    readonly property var mainInstance: pluginApi ? pluginApi.mainInstance : null

    property bool panelReady: true
    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 490 * Style.uiScaleRatio

    property var topProcesses: []
    property var runnersList: []
    property real headerBounceY: 0

    Timer {
        id: headerBounceTimer
        interval: 140
        onTriggered: root.headerBounceY = 0
    }

    FileView {
        id: runnersJsonView
        path: pluginApi ? (pluginApi.pluginDir + "/runners.json") : ""
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                root.runnersList = parsed.runners || [];
            } catch(e) {}
        }
    }

    Process {
        id: psProc
        command: ["sh", "-c", "ps -eo pid,comm,%cpu --sort=-%cpu | sed 1d | head -n 3"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const procs = [];
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/);
                    if (parts.length >= 3) {
                        procs.push({
                            pid: parts[0],
                            name: parts[1],
                            cpu: parts[2] + "%"
                        });
                    }
                }
                root.topProcesses = procs;
                psProc.running = false;
            }
        }
    }

    Timer {
        id: killRefreshTimer
        interval: 600
        repeat: false
        onTriggered: root.refreshTopProcesses()
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
                implicitHeight: headerRow.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    Item {
                        width: 48 * Style.uiScaleRatio
                        height: 36 * Style.uiScaleRatio

                        Image {
                            id: headerPreview
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: pluginApi ? pluginApi.pluginDir + "/runners/" + (mainInstance ? mainInstance.runner : "pixel-cat") + "/preview.png" : ""
                            cache: true
                            y: root.headerBounceY

                            Behavior on y {
                                NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                root.headerBounceY = -6;
                                headerBounceTimer.restart();
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXXS

                        NText {
                            text: mainInstance ? mainInstance.runnerDisplayName : "NoctaCat"
                            pointSize: Style.fontSizeL
                            font.bold: true
                            color: Color.mOnSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        NText {
                            text: (pluginApi ? pluginApi.tr("panel.designedBy") : "Designed by") + ": " + (mainInstance ? mainInstance.runnerAuthor : "Takuto Nakamura")
                            pointSize: Style.fontSizeXS
                            color: Color.mPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        radius: Style.radiusM
                        color: (mainInstance && mainInstance.isSleeping) ? Qt.alpha(Color.mSecondary, 0.2) : ((mainInstance && mainInstance.isTurbo) ? Qt.alpha(Color.mError, 0.2) : Qt.alpha(Color.mPrimary, 0.2))
                        height: 26 * Style.uiScaleRatio
                        width: statusText.implicitWidth + Style.marginM * 2

                        NText {
                            id: statusText
                            anchors.centerIn: parent
                            text: mainInstance ? (mainInstance.paused ? (pluginApi ? pluginApi.tr("panel.statusPaused") : "Paused") : (mainInstance.isSleeping ? (pluginApi ? pluginApi.tr("panel.statusSleeping") : "Sleeping") : (mainInstance.isTurbo ? (pluginApi ? pluginApi.tr("panel.statusTurbo") : "Turbo") : (pluginApi ? pluginApi.tr("panel.statusRunning") : "Running")))) : (pluginApi ? pluginApi.tr("panel.statusRunning") : "Running")
                            pointSize: Style.fontSizeXS
                            font.bold: true
                            color: (mainInstance && mainInstance.isSleeping) ? Color.mSecondary : ((mainInstance && mainInstance.isTurbo) ? Color.mError : Color.mPrimary)
                        }
                    }
                }
            }

            // 2. Telemetry Gauges Card
            NBox {
                Layout.fillWidth: true
                implicitHeight: telemetryGrid.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant

                GridLayout {
                    id: telemetryGrid
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    columns: 3
                    rowSpacing: Style.marginS
                    columnSpacing: Style.marginM

                    ColumnLayout {
                        spacing: Style.marginXXS
                        NText { text: pluginApi ? pluginApi.tr("panel.cpuLoad") : "CPU Load"; pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        NText {
                            text: (mainInstance ? mainInstance.currentMetricValue : 0) + "%"
                            pointSize: Style.fontSizeM; font.bold: true; color: Color.mOnSurface
                        }
                    }

                    ColumnLayout {
                        spacing: Style.marginXXS
                        NText { text: pluginApi ? pluginApi.tr("panel.frequency") : "Frequency"; pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        NText {
                            text: SystemStatService.cpuFreq
                            pointSize: Style.fontSizeM; font.bold: true; color: Color.mOnSurface
                        }
                    }

                    ColumnLayout {
                        spacing: Style.marginXXS
                        NText { text: pluginApi ? pluginApi.tr("panel.frameTick") : "Frame Tick"; pointSize: Style.fontSizeXS; color: Color.mOnSurfaceVariant }
                        NText {
                            text: (mainInstance ? mainInstance.frameIntervalMs : 0) + "ms"
                            pointSize: Style.fontSizeM; font.bold: true; color: Color.mPrimary
                        }
                    }
                }
            }

            // 3. Process Radar (Top 3 Hogs)
            NBox {
                Layout.fillWidth: true
                implicitHeight: processCol.implicitHeight + Style.marginM * 2
                color: Color.mSurfaceVariant

                ColumnLayout {
                    id: processCol
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    RowLayout {
                        Layout.fillWidth: true
                        NText {
                            text: pluginApi ? pluginApi.tr("panel.processRadar") : "Process Radar"
                            pointSize: Style.fontSizeS
                            font.bold: true
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NButton {
                            text: pluginApi ? pluginApi.tr("panel.refresh") : "Refresh"
                            outlined: false
                            backgroundColor: Color.mSurface
                            textColor: Color.mOnSurface
                            onClicked: root.refreshTopProcesses()
                        }
                    }

                    Repeater {
                        model: root.topProcesses
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NText {
                                text: (modelData && modelData.pid) ? modelData.pid : ""
                                pointSize: Style.fontSizeXS
                                family: Style.fontFamilyMonospace
                                color: Color.mOnSurfaceVariant
                                Layout.preferredWidth: 44 * Style.uiScaleRatio
                            }

                            NText {
                                text: (modelData && modelData.name) ? modelData.name : ""
                                pointSize: Style.fontSizeS
                                family: Style.fontFamilyMonospace
                                color: Color.mOnSurface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            NText {
                                text: (modelData && modelData.cpu) ? modelData.cpu : ""
                                pointSize: Style.fontSizeS
                                family: Style.fontFamilyMonospace
                                font.bold: true
                                color: Color.mPrimary
                            }

                            Rectangle {
                                width: 22 * Style.uiScaleRatio
                                height: 22 * Style.uiScaleRatio
                                radius: Style.radiusS
                                color: killArea.containsMouse ? Qt.alpha(Color.mError, 0.25) : Color.mSurface
                                border.color: killArea.containsMouse ? Color.mError : Color.mOutline
                                border.width: Style.borderS

                                NText {
                                    anchors.centerIn: parent
                                    text: pluginApi ? pluginApi.tr("panel.kill") : "✕"
                                    pointSize: Style.fontSizeXS
                                    color: killArea.containsMouse ? Color.mError : Color.mOnSurfaceVariant
                                    font.bold: true
                                }

                                MouseArea {
                                    id: killArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.parent.modelData && parent.parent.modelData.pid) {
                                            Quickshell.execDetached(["kill", "-15", parent.parent.modelData.pid]);
                                            killRefreshTimer.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 4. Full Runner Gallery Horizontal Browser
            RowLayout {
                Layout.fillWidth: true
                NText {
                    text: (pluginApi ? pluginApi.tr("panel.runnerGallery") : "Runner Gallery") + " (" + root.runnersList.length + ")"
                    pointSize: Style.fontSizeS
                    font.bold: true
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }
                NText {
                    text: pluginApi ? pluginApi.tr("panel.scrollHint") : "Scroll horizontally →"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }
            }

            ListView {
                id: runnerListView
                Layout.fillWidth: true
                Layout.preferredHeight: 74 * Style.uiScaleRatio
                orientation: ListView.Horizontal
                spacing: Style.marginS
                clip: true
                model: root.runnersList

                delegate: Rectangle {
                    required property var modelData
                    width: 80 * Style.uiScaleRatio
                    height: 70 * Style.uiScaleRatio
                    radius: Style.radiusM
                    color: (mainInstance && mainInstance.runner === modelData.id) ? Qt.alpha(Color.mPrimary, 0.25) : Color.mSurfaceVariant
                    border.color: (mainInstance && mainInstance.runner === modelData.id) ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.5)
                    border.width: (mainInstance && mainInstance.runner === modelData.id) ? Style.borderM : Style.borderS

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginXS

                        Image {
                            width: 36 * Style.uiScaleRatio
                            height: 26 * Style.uiScaleRatio
                            fillMode: Image.PreserveAspectFit
                            source: pluginApi ? pluginApi.pluginDir + "/runners/" + parent.parent.modelData.id + "/preview.png" : ""
                            cache: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        NText {
                            text: parent.parent.modelData.displayName
                            pointSize: Style.fontSizeXS * 0.85
                            color: (mainInstance && mainInstance.runner === parent.parent.modelData.id) ? Color.mPrimary : Color.mOnSurface
                            font.bold: (mainInstance && mainInstance.runner === parent.parent.modelData.id)
                            elide: Text.ElideRight
                            Layout.maximumWidth: 72 * Style.uiScaleRatio
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (pluginApi) {
                                pluginApi.pluginSettings.runner = parent.modelData.id;
                                pluginApi.saveSettings();
                                if (mainInstance) mainInstance.applyRunnerMeta(parent.modelData.id);
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
                    text: (mainInstance && mainInstance.paused) ? (pluginApi ? pluginApi.tr("panel.resume") : "Resume") : (pluginApi ? pluginApi.tr("panel.pause") : "Pause")
                    icon: (mainInstance && mainInstance.paused) ? "player-play" : "player-pause"
                    outlined: false
                    backgroundColor: Color.mSurfaceVariant
                    textColor: Color.mOnSurface
                    Layout.fillWidth: true
                    onClicked: {
                        if (mainInstance) mainInstance.paused = !mainInstance.paused;
                    }
                }

                NButton {
                    text: pluginApi ? pluginApi.tr("panel.settings") : "All Settings"
                    icon: "settings"
                    outlined: false
                    backgroundColor: Color.mPrimary
                    textColor: Color.mOnPrimary
                    Layout.fillWidth: true
                    onClicked: {
                        var targetScreen = root.screen || (parent && parent.screen) || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
                        if (pluginApi && targetScreen) {
                            BarService.openPluginSettings(targetScreen, pluginApi.manifest);
                        } else {
                            Quickshell.execDetached(["qs", "-c", "noctalia-shell", "ipc", "call", "plugin", "openSettings", "noctacat"]);
                        }
                    }
                }
            }
        }
    }
}
