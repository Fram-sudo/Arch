// Dock.qml — Dock auto-caché, trait iPhone, icônes Papirus
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PanelWindow {
    id: root

    required property var screen

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    property int dockMaxHeight: Math.round((Theme.dockHeight - 12) * 1.45) + 12
    implicitHeight: dockMaxHeight + Theme.dockMargin + 8

    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    color:         "transparent"

    property bool revealed: false

    // ── Trait indicateur style iPhone ──────────────────────────────────────
    Rectangle {
        id: hintLine
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        width:  dockBg.width * 1
        height: 4
        radius: 2
        color:  Theme.isDark
                ? Qt.rgba(1, 1, 1, 0.30)
                : Qt.rgba(0, 0, 0, 0.22)

        property bool showing: true

        anchors.bottomMargin: showing ? 3 : -8
        opacity: showing ? 0.65 : 0.0

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Timer {
            id: hintShowTimer
            interval: 320
            onTriggered: hintLine.showing = true
        }

        Connections {
            target: root
            function onRevealedChanged() {
                if (root.revealed) {
                    hintShowTimer.stop()
                    hintLine.showing = false
                } else {
                    hintShowTimer.restart()
                }
            }
        }
    }

    // ── Zone de détection (bas de l'écran) ────────────────────────────────
    MouseArea {
        id: triggerZone
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        width:  dockBg.width
        height: 8
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            if (containsMouse) {
                hideTimer.stop()
                root.revealed = true
            } else if (!dockSurface.hovered) {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: root.revealed = false
    }

    // ── Liste des applications ─────────────────────────────────────────────
    ListModel {
        id: appsModel
        ListElement { appName: "File Explorer";    iconName: "org.kde.dolphin";     cmd0: "dolphin";          cmd1: ""; cmd2: ""; wmClass: "dolphin"               }
        ListElement { appName: "Terminal";    iconName: "kitty";               cmd0: "kitty";            cmd1: ""; cmd2: ""; wmClass: "kitty"                  }
        ListElement { appName: "Firefox";     iconName: "firefox";             cmd0: "firefox";          cmd1: ""; cmd2: ""; wmClass: "firefox"                }
    }

    // ── Conteneur dock ────────────────────────────────────────────────────
    Item {
        id: dockBg

        property int itemSzBase:     Theme.dockHeight - 12
        property int itemSzMax:      Math.round(itemSzBase * 1.45)  // taille max fixe
        property int itemSpacing:    8
        property int cnt:            appsModel.count
        property int dragIndex:      -1
        property int contentWidth:   cnt * itemSzBase + (cnt - 1) * itemSpacing
        property int containerPadding: 10

        width:  contentWidth + containerPadding * 2 + 8
        height: itemSzMax + 12
        clip:   false

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     root.revealed ? Theme.dockMargin : -(dockBg.height + 4)

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: dockSurface
            onHoveredChanged: {
                if (hovered)      hideTimer.stop()
                else if (!triggerZone.containsMouse) hideTimer.restart()
            }
        }

        // ── Fond glassmorphism ─────────────────────────────────────────────
        Rectangle {
            id: dockContainer
            anchors.bottom:           parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width:  dockBg.contentWidth + dockBg.containerPadding * 2 + 8
            height: dockBg.itemSzBase + 16
            radius: Theme.dockRadius
            color:  Theme.glassBg
            border.color: Theme.glassBorder
            border.width: Theme.glassBorderWidth

            Rectangle {
                anchors.top:   parent.top
                anchors.left:  parent.left
                anchors.right: parent.right
                height: parent.height * Theme.glossHeight
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.glossTop   }
                    GradientStop { position: 1.0; color: Theme.glossBottom }
                }
            }
        }

        // ── Ligne d'icônes ────────────────────────────────────────────────
        Row {
            id: dockRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     8
            spacing: dockBg.itemSpacing

            move: Transition {
                NumberAnimation { property: "x"; duration: 180; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: appsModel

                delegate: Item {
                    id: dockItem

                    property bool hovered:  false
                    property bool dragging: dockBg.dragIndex === index

                    property bool isOpen: {
                        if (!wmClass) return false
                        var wins = Hyprland.windows.values
                        for (var i = 0; i < wins.length; i++)
                            if (wins[i].resourceClass.toLowerCase() === wmClass.toLowerCase())
                                return true
                        return false
                    }
                    property bool isFocused: {
                        var w = Hyprland.activeWindow
                        if (!w || !wmClass) return false
                        return w.resourceClass.toLowerCase() === wmClass.toLowerCase()
                    }

                    property real targetSize: (hovered && !dragging)
                                              ? dockBg.itemSzMax
                                              : dockBg.itemSzBase

                    width:  targetSize
                    height: dockBg.itemSzBase
                    z:      dragging ? 10 : 1

                    Behavior on width {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }

                    transform: Translate {
                        x: dockItem.dragging ? dragHandler.activeTranslation.x : 0
                        Behavior on x {
                            enabled: !dockItem.dragging
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    // ── Tooltip ───────────────────────────────────────────
                    // Positionné à y fixe calculé depuis le bas du dockItem,
                    // basé sur la taille MAX de l'icône — jamais recouvert.
                    Rectangle {
                        id: tooltip
                        x: (dockItem.width - width) / 2
                        // bas de l'icône à taille max = dockItem.height - (itemSzMax - 8) - 2
                        // on remonte encore de height + 6px de gap
                        y: dockItem.height - (dockBg.itemSzMax - 10) - 2 - height - 0
                        z: 20
                        width:  ttLabel.implicitWidth + 14
                        height: 20
                        radius: 6
                        color:  Theme.popupBg
                        border.color: Theme.glassBorder
                        border.width: 1
                        opacity: dockItem.hovered && !dockItem.dragging ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 130 } }

                        Text {
                            id: ttLabel
                            anchors.centerIn: parent
                            text: appName
                            color: Theme.fg
                            font.family:    Theme.font
                            font.pixelSize: Theme.fontSizeXs
                            font.weight:    Font.Medium
                        }
                    }

                    // ── Icône Papirus ─────────────────────────────────────
                    Image {
                        id: appIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        width:  dockItem.targetSize - 8
                        height: dockItem.targetSize - 8
                        source:  Quickshell.iconPath(iconName, true)
                        visible: status === Image.Ready
                        smooth:  true
                        mipmap:  true
                        Behavior on width  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        SequentialAnimation {
                            id: bounceAnim; running: false
                            NumberAnimation { target: appIcon; property: "scale"; to: 0.85; duration: 80;  easing.type: Easing.OutQuad    }
                            NumberAnimation { target: appIcon; property: "scale"; to: 1.10; duration: 120; easing.type: Easing.OutQuad    }
                            NumberAnimation { target: appIcon; property: "scale"; to: 1.0;  duration: 240; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.4 }
                        }
                    }

                    // Fallback texte
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        text:    appName.charAt(0)
                        color:   Theme.fg
                        font.family:    Theme.font
                        font.pixelSize: dockItem.targetSize * 0.5
                        font.bold:      true
                        visible: appIcon.status !== Image.Ready
                    }

                    // ── Point indicateur "ouvert" ─────────────────────────
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     -2
                        width:  dockItem.isFocused ? 5 : 3
                        height: dockItem.isFocused ? 5 : 3
                        radius: height / 2
                        color:  dockItem.isFocused ? Theme.red : Theme.fgMuted
                        opacity: dockItem.isOpen ? 1.0 : 0.0
                        Behavior on width   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color   { ColorAnimation  { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // ── Drag ──────────────────────────────────────────────
                    DragHandler {
                        id: dragHandler
                        xAxis.enabled: true
                        yAxis.enabled: false
                        onActiveChanged: {
                            if (active) {
                                dockBg.dragIndex = index
                                dockItem.hovered = false
                            } else {
                                var step   = dockBg.itemSzBase + dockBg.itemSpacing
                                var moved  = Math.round(dragHandler.activeTranslation.x / step)
                                var newIdx = Math.max(0, Math.min(appsModel.count - 1, index + moved))
                                if (newIdx !== index) appsModel.move(index, newIdx, 1)
                                dockBg.dragIndex = -1
                            }
                        }
                    }

                    // ── Clic ──────────────────────────────────────────────
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        cursorShape: dockItem.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        onEntered:  if (!dockItem.dragging) dockItem.hovered = true
                        onExited:   dockItem.hovered = false
                        onClicked: {
                            if (dockItem.dragging) return
                            bounceAnim.restart()
                            if (dockItem.isOpen && wmClass) {
                                Hyprland.dispatch("focuswindow class:" + wmClass)
                                return
                            }
                            var c = []
                            if (cmd0) c.push(cmd0)
                            if (cmd1) c.push(cmd1)
                            if (cmd2) c.push(cmd2)
                            Quickshell.execDetached(c)
                        }
                    }
                }
            }
        }
    }
}
