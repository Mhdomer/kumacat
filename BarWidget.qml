import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi ? pluginApi.mainInstance : null
    readonly property string screenName: screen ? screen.name : ""
    readonly property string resolvedBarPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: resolvedBarPosition === "left" || resolvedBarPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

    readonly property bool isSleeping: mainInstance ? mainInstance.isSleeping : false
    readonly property bool isPaused: mainInstance ? mainInstance.paused : false
    readonly property bool isTurbo: mainInstance ? mainInstance.isTurbo : false
    readonly property bool showBadge: mainInstance ? mainInstance.showBadge : false
    readonly property real catScale: mainInstance ? mainInstance.catScale : 1.0
    readonly property real catOffsetY: mainInstance ? mainInstance.catOffsetY : 0.0

    readonly property color resolvedCatColor: {
        if (!mainInstance) return "#FFFFFF";
        if (mainInstance.catColor === "rainbow") return mainInstance.currentRainbowColor;
        if (mainInstance.isTurbo || mainInstance.catColor === "error") return Color.mError;
        if (mainInstance.catColor === "primary") return Color.mPrimary;
        if (mainInstance.catColor === "secondary") return Color.mSecondary;
        return mouseArea.containsMouse ? Color.mPrimary : "#FFFFFF";
    }

    readonly property string currentSpriteSource: {
        if (!pluginApi || !mainInstance) return "";
        const base = pluginApi.pluginDir + "/runners/" + mainInstance.runner;
        if ((isSleeping || isPaused) && mainInstance.hasSleepFrame) {
            return base + "/sleep.png";
        }
        return base + "/frame-" + mainInstance.currentFrame + ".png";
    }

    readonly property bool onlyPrimaryScreen: mainInstance ? mainInstance.onlyPrimaryScreen : false
    readonly property bool isPrimaryScreen: screen ? (Quickshell.screens.length > 0 && screen === Quickshell.screens[0]) : true
    visible: !onlyPrimaryScreen || isPrimaryScreen

    property real petBounceY: 0
    property string petEmoteText: "♥"

    function petTheCat() {
        const emotes = ["♥", "meow~", "purr~", "✨", "^•ﻌ•^"];
        petEmoteText = emotes[Math.floor(Math.random() * emotes.length)];
        petAnim.restart();
    }

    SequentialAnimation {
        id: petAnim
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: root; property: "petBounceY"; to: -8; duration: 120; easing.type: Easing.OutQuad }
                NumberAnimation { target: root; property: "petBounceY"; to: 0; duration: 160; easing.type: Easing.OutBounce }
            }
            SequentialAnimation {
                PropertyAction { target: petBadge; property: "visible"; value: true }
                NumberAnimation { target: petBadge; property: "opacity"; from: 0; to: 1; duration: 100 }
                ParallelAnimation {
                    NumberAnimation { target: petBadge; property: "y"; from: -4; to: -22; duration: 750; easing.type: Easing.OutCubic }
                    NumberAnimation { target: petBadge; property: "opacity"; from: 1; to: 0; duration: 750 }
                }
                PropertyAction { target: petBadge; property: "visible"; value: false }
            }
        }
    }

    readonly property real runnerHeight: capsuleHeight * 0.72 * catScale
    readonly property real contentWidth: isBarVertical
        ? capsuleHeight
        : (showBadge ? runnerHeight * 1.5 + badgeText.implicitWidth + Style.marginM * 2 : runnerHeight * 1.5 + Style.marginM * 1.5)
    readonly property real contentHeight: capsuleHeight

    implicitWidth: visible ? contentWidth : 0
    implicitHeight: visible ? contentHeight : 0

    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : (isTurbo ? Qt.alpha(Color.mError, 0.15) : Style.capsuleColor)
        border.color: isTurbo ? Color.mError : Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on color {
            ColorAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.capsuleHeight * root.catOffsetY + root.petBounceY
            spacing: Style.marginXS

            Item {
                id: spriteContainer
                width: root.runnerHeight * 1.5
                height: root.runnerHeight
                Layout.alignment: Qt.AlignVCenter

                NText {
                    id: petBadge
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -4
                    visible: false
                    text: root.petEmoteText
                    font.bold: true
                    pointSize: Style.fontSizeS
                    color: Color.mPrimary
                    z: 10
                }

                Image {
                    id: runnerImg
                    anchors.centerIn: parent
                    height: parent.height
                    width: parent.width
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: false
                    source: root.currentSpriteSource

                    layer.enabled: Boolean(mainInstance && mainInstance.runnerType === "monochrome" && root.resolvedCatColor !== "#FFFFFF")
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: root.resolvedCatColor
                    }
                }

                Repeater {
                    id: zzzEffect
                    model: 3
                    delegate: NText {
                        id: zText
                        required property int index
                        text: pluginApi ? pluginApi.tr("widget.sleepParticle") : "z"
                        font.pixelSize: root.runnerHeight * (0.35 + index * 0.08)
                        font.bold: true
                        color: root.resolvedCatColor
                        visible: root.isSleeping
                        opacity: 0
                        x: spriteContainer.width * 0.65 + index * 5
                        y: spriteContainer.height * 0.3

                        SequentialAnimation {
                            running: root.isSleeping
                            loops: Animation.Infinite

                            PauseAnimation { duration: zText.index * 450 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: zText; property: "y"
                                    from: spriteContainer.height * 0.3
                                    to: -10
                                    duration: 1600
                                    easing.type: Easing.OutQuad
                                }
                                SequentialAnimation {
                                    NumberAnimation { target: zText; property: "opacity"; from: 0; to: 1; duration: 300 }
                                    NumberAnimation { target: zText; property: "opacity"; from: 1; to: 0; duration: 1300 }
                                }
                            }
                        }
                    }
                }
            }

            NText {
                id: badgeText
                visible: root.showBadge && !root.isBarVertical
                text: (mainInstance ? mainInstance.currentMetricValue : 0) + "%"
                pointSize: Style.fontSizeXS
                font.bold: true
                color: root.resolvedCatColor
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi ? pluginApi.tr("contextMenu.pet") : "Pet",
                "action": "pet",
                "icon": "heart"
            },
            {
                "label": isPaused ? (pluginApi ? pluginApi.tr("contextMenu.resume") : "Resume") : (pluginApi ? pluginApi.tr("contextMenu.pause") : "Pause"),
                "action": "toggle-pause",
                "icon": isPaused ? "player-play" : "player-pause"
            },
            {
                "label": pluginApi ? pluginApi.tr("contextMenu.settings") : "Settings",
                "action": "widget-settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "pet") {
                root.petTheCat();
            } else if (action === "widget-settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            } else if (action === "toggle-pause" && mainInstance) {
                mainInstance.paused = !mainInstance.paused;
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.petTheCat();
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (pluginApi) {
                    pluginApi.openPanel(root.screen, root);
                }
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen);
            } else if (mouse.button === Qt.MiddleButton && mainInstance) {
                mainInstance.paused = !mainInstance.paused;
            }
        }
    }
}
