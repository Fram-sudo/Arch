// Dashboard.qml — Widget central, SUPER+A
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win

    property bool open: false

    signal closeRequested()

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       true

    property int panelW: 780
    property int panelH: 520
    property int panelX: (win.width  - panelW) / 2
    property int panelY: (win.height - panelH) / 2 - 40

    property int currentPage: 0
    readonly property int pageCount: 3

    // ── Raccourci SUPER+A ─────────────────────────────────────────────────
    GlobalShortcut {
        name:        "dashboardToggle"
        description: "Toggle dashboard"
        onPressed: {
            win.open = !win.open
            if (win.open) win.currentPage = 0
        }
    }

    // ── Raccourci ÉCHAP ───────────────────────────────────────────────────
    GlobalShortcut {
        name:        "dashboardClose"
        description: "Close dashboard"
        onPressed:   win.open = false
    }

    // ── Fermeture au clic hors panneau ────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        enabled: win.open
        onClicked: mouse => {
            var inPanel = mouse.x >= win.panelX &&
                          mouse.x <= win.panelX + win.panelW &&
                          mouse.y >= win.panelY &&
                          mouse.y <= win.panelY + win.panelH
            if (!inPanel) win.open = false
        }
        propagateComposedEvents: true
    }

    // ── Overlay : fond flouté sombre opaque ───────────────────────────────
    Item {
        anchors.fill: parent
        opacity: win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        FastBlur {
            anchors.fill: parent
            source: ShaderEffectSource {
                sourceRect: Qt.rect(0, 0, win.width, win.height)
            }
            radius: 90
        }

        // Fond très sombre et opaque par-dessus le blur
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.88)
        }
    }

    // ── Panneau principal — toujours sombre ───────────────────────────────
    Rectangle {
        id: panel
        x:      win.panelX
        y:      win.open ? win.panelY : win.panelY + 30
        width:  win.panelW
        height: win.panelH
        radius: 22
        color:  "#111010"
        border.color: "transparent"
        border.width: 0
        clip: true

        opacity: win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { id: anim; duration: 300; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset:  0
            verticalOffset:    16
            radius:            48
            samples:           64
            color:             Qt.rgba(0, 0, 0, 0.60)
        }

        // Glossy top subtil
        Rectangle {
            z: 2
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: parent.height * 0.35
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.03) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Contenu pages ─────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            anchors.bottomMargin: 40
            z: 1

            DashPage {
                anchors.fill: parent
                visible: win.currentPage === 0
                active:  win.open && win.currentPage === 0
            }

            AudioPage {
                anchors.fill: parent
                visible: win.currentPage === 1
                active:  win.open && win.currentPage === 1
            }

            SystemPage {
                anchors.fill: parent
                visible: win.currentPage === 2
                active:  win.open && win.currentPage === 2
            }
        }

        // ── Navigation dots ───────────────────────────────────────────────
        Row {
            z: 3
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     12
            spacing: 8

            Text {
                text: "‹"
                color: win.currentPage > 0 ? Theme.popupFg : Theme.popupFgDim
                font.family: Theme.font; font.pixelSize: 16; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: if (win.currentPage > 0) win.currentPage--
                }
            }

            Repeater {
                model: win.pageCount
                delegate: Rectangle {
                    required property int index
                    property bool active: win.currentPage === index
                    width:  active ? 20 : 6; height: 6; radius: 3
                    color:  active ? Theme.red : Theme.popupFgDim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 200 } }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: win.currentPage = index
                    }
                }
            }

            Text {
                text: "›"
                color: win.currentPage < win.pageCount - 1 ? Theme.popupFg : Theme.popupFgDim
                font.family: Theme.font; font.pixelSize: 16; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: if (win.currentPage < win.pageCount - 1) win.currentPage++
                }
            }
        }
    }
}
