// TopBar.qml — Barre principale glassmorphism flottante
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs
import qs.bar.popups

PanelWindow {
    id: root

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    implicitHeight: Theme.barHeight
    color:          "transparent"
    exclusionMode:  ExclusionMode.Auto

    property string currentTime: "00:00"
    property string currentDate: "sam 1 jan"

    // ── Popups ────────────────────────────────────────────────────────────
    property bool powerOpen:    false
    property bool calendarOpen: false
    property bool qsOpen:       false

    function closeAll()        { powerOpen = false; calendarOpen = false; qsOpen = false }
    function togglePower()     { var v = !powerOpen;    closeAll(); powerOpen    = v }
    function toggleCalendar()  { var v = !calendarOpen; closeAll(); calendarOpen = v }
    function toggleQs()        { var v = !qsOpen;       closeAll(); qsOpen       = v }

    // Overlay plein écran — ferme tout au clic hors popup (déclaré AVANT les popups pour être en dessous)
    PanelWindow {
        screen: root.screen
        anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
        color: "transparent"; exclusionMode: ExclusionMode.Ignore; aboveWindows: true
        visible: root.powerOpen || root.calendarOpen || root.qsOpen
        MouseArea { anchors.fill: parent; onClicked: root.closeAll() }
    }

    PowerMenu {
        id: powerMenuWin; screen: root.screen
        open: root.powerOpen; onOpenChanged: root.powerOpen = open
    }
    CalendarPopup {
        id: calendarWin; screen: root.screen
        open: root.calendarOpen; onOpenChanged: root.calendarOpen = open
        clockCenterX: root.screen ? root.screen.width / 2 : 0
    }
    QuickSettings {
        id: qsWin; screen: root.screen
        open: root.qsOpen; onOpenChanged: root.qsOpen = open
    }

    // Volume (pour l'icône dans la barre)
    property var  pwSink:  Pipewire.defaultAudioSink
    property real vol:     pwSink && pwSink.audio ? pwSink.audio.volume : 0
    property bool muted:   pwSink && pwSink.audio ? pwSink.audio.muted  : false

    // ── Fond opaque pleine largeur ──────────────────────────────────────
    Rectangle {
        id: barBg
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        height: Theme.barHeight
        radius: Theme.barRadius
        color:  Theme.barBg

        RowLayout {
            anchors.fill:         parent
            anchors.leftMargin:   10
            anchors.rightMargin:  10
            anchors.topMargin:    2
            anchors.bottomMargin: 2
            spacing: 0

            // ══ GAUCHE : icône Arch + workspaces ═════════════════════════
            RowLayout {
                spacing: 6

                Rectangle {
                    width: Theme.barHeight - 10; height: Theme.barHeight - 10; radius: 6
                    color: appMa.containsMouse ? Theme.glassHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent; text: "󰣇"
                        color: Theme.red; font.family: Theme.font; font.pixelSize: Theme.iconSize + 2
                    }
                    MouseArea {
                        id: appMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.closeAll(); Quickshell.execDetached(["rofi","-show","drun"]) }
                    }
                }

                Rectangle {
                    height: Theme.barHeight - 12
                    width:  wsRow.implicitWidth + 12
                    radius: height / 2
                    color:  Qt.rgba(1, 1, 1, 0.06)

                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 5
                        property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

                        Repeater {
                            model: 4
                            delegate: Item {
                                required property int index
                                property int  wsId:   index + 1
                                property bool active: wsRow.activeWs === wsId
                                property bool busy: {
                                    var ws = Hyprland.workspaces.values
                                    for (var i = 0; i < ws.length; i++)
                                        if (ws[i].id === wsId) return true
                                    return false
                                }
                                width:  active ? 20 : 6
                                height: Theme.barHeight - 12
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width:   parent.width
                                    height:  active ? 6 : (busy ? 4 : 3)
                                    radius:  height / 2
                                    color:   active ? Theme.red : (busy ? Theme.fgMuted : Qt.rgba(1,1,1,0.2))
                                    Behavior on width  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on color  { ColorAnimation  { duration: 180 } }

                                    SequentialAnimation on scale {
                                        id: waveAnim; running: false
                                        NumberAnimation { to: 1.2;  duration: 90;  easing.type: Easing.OutQuad }
                                        NumberAnimation { to: 1.0;  duration: 200; easing.type: Easing.OutElastic; easing.amplitude: 1.4; easing.period: 0.3 }
                                    }
                                    onColorChanged: if (active) waveAnim.restart()
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + wsId)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
            Item { Layout.fillWidth: true }

            // ══ DROITE : flèche QS + Power ═══════════════════════════════
            RowLayout {
                spacing: 4

                // Bouton QuickSettings — flèche vers le bas
                Rectangle {
                    width: Theme.barHeight - 10; height: Theme.barHeight - 10; radius: 5
                    color: qsMa.containsMouse || root.qsOpen ? Theme.glassHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅀"
                        color: root.qsOpen ? Theme.red : Theme.fg
                        font.family: Theme.font; font.pixelSize: Theme.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Rotation quand le panneau est ouvert
                        rotation: root.qsOpen ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: qsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleQs()
                        onWheel: wheel => {
                            var d = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                            Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@",d])
                        }
                    }
                }

                // Bouton Power
                Rectangle {
                    width: Theme.barHeight - 10; height: Theme.barHeight - 10; radius: 5
                    color: pwrMa.containsMouse || root.powerOpen ? Theme.red : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent; text: "⏻"
                        color: pwrMa.containsMouse || root.powerOpen ? "#fff" : Theme.red
                        font.family: Theme.font; font.pixelSize: Theme.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea { id: pwrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePower() }
                }
            }
        }

        // ══ CENTRE — horloge ═════════════════════════════════════════════
        Rectangle {
            anchors.centerIn: parent
            height: Theme.barHeight - 8
            width:  clockRow.implicitWidth + 20
            radius: (Theme.barHeight - 8) / 2
            color:  clockMa.containsMouse || root.calendarOpen ? Theme.glassHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: root.currentTime
                    color: root.calendarOpen ? Theme.red : Theme.fg
                    font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Rectangle {
                    width: 1; height: Theme.barHeight - 18
                    color: Qt.rgba(1,1,1,0.12)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.currentDate; color: Theme.fgMuted
                    font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: clockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleCalendar()
            }
        }
    }

    // ── Horloge ───────────────────────────────────────────────────────────
    Process {
        id: timeProc; command: ["date", "+%H:%M"]; running: true
        stdout: StdioCollector { onStreamFinished: root.currentTime = this.text.trim() }
    }
    Process {
        id: dateProc; command: ["date", "+%a %e %b"]; running: true
        stdout: StdioCollector { onStreamFinished: root.currentDate = this.text.trim().toLowerCase() }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { timeProc.running = true; dateProc.running = true }
    }
}
