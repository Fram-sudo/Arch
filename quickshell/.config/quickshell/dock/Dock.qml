// Dock.qml
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PanelWindow {
    id: root

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    property int dockMaxHeight: Math.round((Theme.dockHeight - 12) * 1.45) + 12
    implicitHeight: dockMaxHeight + Theme.dockMargin + 8

    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    color:         "transparent"

    property bool revealed: false

    // ── Trait indicateur style iPhone ─────────────────────────────────────
    Rectangle {
        id: hintLine
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     3
        width:  dockBg.width * 1
        height: 5
        radius: 2
        color:  Qt.rgba(226/255, 217/255, 224/255, 0.25)
        visible: !root.revealed

        opacity: triggerZone.containsMouse ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Zone de détection ────────────────────────────────────────────────
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

    ListModel {
        id: appsModel
        ListElement { appName: "Fichiers";     iconName: "org.kde.dolphin";     cmd0: "dolphin"; cmd1: "";      cmd2: "";     wmClass: "dolphin" }
        ListElement { appName: "Terminal";     iconName: "kitty";               cmd0: "kitty";   cmd1: "";      cmd2: "";     wmClass: "kitty"   }
        ListElement { appName: "Firefox";      iconName: "firefox";             cmd0: "firefox"; cmd1: "";      cmd2: "";     wmClass: "firefox" }
    }

    Item {
        id: dockBg

        property int itemSzBase: Theme.dockHeight - 12
        property int itemSpacing: 8
        property int cnt: appsModel.count
        property int dragIndex: -1

        width:  cnt * itemSzBase + (cnt - 1) * itemSpacing + 20
        height: Math.round(itemSzBase * 1.45) + 12
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

                    property real targetSize: (hovered && !dragging)
                                              ? dockBg.itemSzBase * 1.45
                                              : dockBg.itemSzBase

                    width:  targetSize
                    height: dockBg.itemSzBase
                    z:      dragging ? 10 : 1

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    transform: Translate {
                        x: dockItem.dragging ? dragHandler.activeTranslation.x : 0
                        Behavior on x {
                            enabled: !dockItem.dragging
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        width:  dockItem.targetSize - 8
                        height: dockItem.targetSize - 8
                        source:  Quickshell.iconPath(iconName, true)
                        visible: source !== ""
                        smooth:  true
                        mipmap:  true
                        Behavior on width  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        text:    appName.charAt(0)
                        color:   Theme.fg
                        font.family:    Theme.font
                        font.pixelSize: dockItem.targetSize * 0.5
                        font.bold:      true
                        visible: Quickshell.iconPath(iconName, true) === ""
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     1
                        width: {
                            if (!wmClass) return 0
                            var wins = Hyprland.windows.values
                            for (var i = 0; i < wins.length; i++)
                                if (wins[i].resourceClass.toLowerCase() === wmClass.toLowerCase()) return 10
                            return 0
                        }
                        height: 3; radius: 2; color: "#A32335"
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

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
                                if (newIdx !== index)
                                    appsModel.move(index, newIdx, 1)
                                dockBg.dragIndex = -1
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        cursorShape: dockItem.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        onEntered:  if (!dockItem.dragging) dockItem.hovered = true
                        onExited:   dockItem.hovered = false
                        onClicked: {
                            if (!dockItem.dragging) {
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
}
