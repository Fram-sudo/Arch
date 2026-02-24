// PowerMenu.qml — Popup power (PanelWindow séparé)
import QtQuick
import Quickshell

PanelWindow {
    id: win
    property bool open: false

    anchors.top:   true
    anchors.right: true
    margins.top:   theme.barHeight + 4
    margins.right: 4

    implicitWidth:  160
    implicitHeight: 4 * 36 + 10

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

    Theme { id: theme }

    Rectangle {
        anchors.fill: parent
        radius:       theme.popupRadius
        color:        theme.bgPopup
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.5)
        border.width: 1

        opacity:      win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 140 } }

        property var entries: [
            { label: "Éteindre",    icon: "⏻", cmd: ["systemctl","poweroff"]  },
            { label: "Redémarrer",  icon: "↺", cmd: ["systemctl","reboot"]    },
            { label: "Verrouiller", icon: "󰌾", cmd: ["hyprlock"]              },
            { label: "Veille",      icon: "⏾", cmd: ["systemctl","suspend"]   }
        ]

        Column {
            anchors.fill:    parent
            anchors.margins: 5
            spacing:         2

            Repeater {
                model: parent.parent.entries
                delegate: Rectangle {
                    required property var modelData
                    width:  148; height: 36; radius: 7
                    color:  ma.containsMouse ? theme.red : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 10
                        Text {
                            text: modelData.icon
                            color: ma.containsMouse ? "#fff" : theme.red
                            font.family: theme.font; font.pixelSize: theme.fontSizeSm + 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        Text {
                            text: modelData.label
                            color: ma.containsMouse ? "#fff" : theme.fg
                            font.family: theme.font; font.pixelSize: theme.fontSizeSm
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                    MouseArea {
                        id: ma; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { win.open = false; Quickshell.execDetached(modelData.cmd) }
                    }
                }
            }
        }
    }
}
