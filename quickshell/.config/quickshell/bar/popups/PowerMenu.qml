// PowerMenu.qml — Power menu style macOS Tahoe
import QtQuick
import Quickshell
import qs

PanelWindow {
    id: win
    property bool open: false

    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight + 6
    margins.right: 8

    implicitWidth:  180
    property int popupGap: 6
    property int contentH: entries.count * 38 + 16
    implicitHeight: contentH + popupGap

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    property var entries: [
        { label: "Éteindre",    icon: "⏻", cmd: ["systemctl","poweroff"]  },
        { label: "Redémarrer",  icon: "↺", cmd: ["systemctl","reboot"]    },
        { label: "Verrouiller", icon: "󰌾", cmd: ["hyprlock"]              },
        { label: "Veille",      icon: "⏾", cmd: ["systemctl","suspend"]   }
    ]

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: pmPanel
            width:  parent.width
            height: win.contentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            y: win.open ? win.popupGap : -height - 10
            Behavior on y {
                NumberAnimation {
                    id: slideAnim
                    duration: 300
                    easing.type: win.open ? Easing.OutQuart : Easing.InQuart
                }
            }
            opacity: win.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

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
                anchors.fill: parent; anchors.margins: 8
                spacing: 2

                Repeater {
                    id: entries
                    model: win.entries
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 36; radius: 8
                        color: ma.containsMouse ? Theme.popupAccentBright : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 10
                            spacing: 10
                            Text {
                                text: modelData.icon
                                color: ma.containsMouse ? "#fff" : Theme.red
                                font.family: Theme.fontMono; font.pixelSize: 13
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                            Text {
                                text: modelData.label
                                color: ma.containsMouse ? "#fff" : Theme.popupFg
                                font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { win.open = false; Quickshell.execDetached(modelData.cmd) }
                        }
                    }
                }
            }
        }
    }
}
