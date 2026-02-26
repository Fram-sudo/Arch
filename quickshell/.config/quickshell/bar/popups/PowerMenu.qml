// PowerMenu.qml — Popup power
import QtQuick
import Quickshell
import qs

PanelWindow {
    id: win
    property bool open: false

    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight
    margins.right: 4

    implicitWidth:  160
    property int popupContentH: 4 * 36 + 10
    property int popupGap: 10
    implicitHeight: popupContentH + popupGap

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || pmSlideAnim.running

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
            width: parent.width
            height: win.popupContentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            y: win.open ? win.popupGap : -height
            Behavior on y { NumberAnimation { id: pmSlideAnim; duration: 300; easing.type: Easing.OutQuart } }

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
                    model: win.entries
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 36; radius: 9
                        color: ma.containsMouse ? Theme.popupAccentBright : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: modelData.icon
                                color: ma.containsMouse ? "#fff" : Theme.popupAccent
                                font.family: Theme.font; font.pixelSize: Theme.fontSizeSm + 1
                                Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                            }
                            Text {
                                text: modelData.label
                                color: ma.containsMouse ? "#fff" : Theme.popupFg
                                font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                                Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
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
}
