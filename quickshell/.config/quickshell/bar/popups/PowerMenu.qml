// PowerMenu.qml — Popup power, pattern plein écran MouseArea
import QtQuick
import Quickshell
import qs

PanelWindow {
    id: win
    property bool open: false
    property int  buttonCenterX: 0

    signal closeRequested()

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    property int panelWidth:  160
    property int panelTop:    Theme.barHeight + 6
    property int panelLeft:   Math.min(
                                  Math.max(8, buttonCenterX - panelWidth / 2),
                                  win.width - panelWidth - 8)
    property int contentH:    4 * 40 + 16

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            var inPanel = (mouse.x >= win.panelLeft &&
                           mouse.x <= win.panelLeft + win.panelWidth &&
                           mouse.y >= win.panelTop &&
                           mouse.y <= win.panelTop + win.contentH)
            if (!inPanel) win.closeRequested()
        }
        propagateComposedEvents: true
    }

    property var entries: [
        { label: "Éteindre",    icon: "󰐥", cmd: ["systemctl", "poweroff"]  },
        { label: "Redémarrer",  icon: "󰑓", cmd: ["systemctl", "reboot"]    },
        { label: "Verrouiller", icon: "󰌾", cmd: ["hyprlock"]               },
        { label: "Veille",      icon: "󰤄", cmd: ["systemctl", "suspend"]   }
    ]

    Item {
        anchors.fill: parent

        Rectangle {
            id: pmPanel
            x:      win.panelLeft
            width:  win.panelWidth
            height: win.contentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            y: win.open ? win.panelTop : win.panelTop - height - 10
            Behavior on y {
                NumberAnimation {
                    id: slideAnim
                    duration: 320
                    easing.type: win.open ? Easing.OutQuart : Easing.InQuart
                }
            }
            opacity: win.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 280 } }

            Rectangle {
                z: 0
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: parent.height * Theme.popupGlossHeight; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.popupGlossTop }
                    GradientStop { position: 1.0; color: Theme.popupGlossBottom }
                }
            }

            Column {
                z: 1
                anchors.fill:    parent
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: win.entries
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 40; radius: 8
                        color: entryMa.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                        border.color: entryMa.containsMouse ? Qt.rgba(1,1,1,0.20) : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:           parent.left
                            anchors.leftMargin:     12
                            spacing: 10
                            Text {
                                text: modelData.icon
                                color: "#fff"
                                font.family: Theme.fontMono; font.pixelSize: Theme.iconSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                color: entryMa.containsMouse ? "#fff" : Qt.rgba(1,1,1,0.75)
                                font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }
                        MouseArea {
                            id: entryMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { win.open = false; Quickshell.execDetached(modelData.cmd) }
                        }
                    }
                }
            }
        }
    }
}
