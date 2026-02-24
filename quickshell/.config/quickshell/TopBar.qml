// TopBar.qml — Barre principale
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

PanelWindow {
    id: root

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    implicitHeight: theme.barHeight
    color:          "transparent"
    exclusionMode:  ExclusionMode.Auto

    Theme { id: theme }

    property string currentTime: "00:00"
    property string currentDate: "sam 1 jan"

    // ── Popups ────────────────────────────────────────────────────────────
    property bool powerOpen:    false
    property bool calendarOpen: false
    property bool mediaOpen:    false
    property bool controlsOpen: false

    PowerMenu    { id: powerMenuWin;  screen: root.screen; open: root.powerOpen;    onOpenChanged: root.powerOpen    = open }
    CalendarPopup{
        id: calendarWin;  screen: root.screen; open: root.calendarOpen
        onOpenChanged: root.calendarOpen = open
        clockCenterX: root.screen ? root.screen.width / 2 : 0
    }
    MediaPopup   { id: mediaWin;      screen: root.screen; open: root.mediaOpen;    onOpenChanged: root.mediaOpen    = open }
    ControlsPopup{
        id: controlsWin;  screen: root.screen; open: root.controlsOpen
        onOpenChanged: root.controlsOpen = open
        buttonRightX: ctrlBtn.mapToItem(null, ctrlBtn.width, 0).x
    }

    // Overlay plein écran — ferme tout au clic hors barre
    PanelWindow {
        screen: root.screen
        anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
        color: "transparent"; exclusionMode: ExclusionMode.Ignore
        visible: root.powerOpen || root.calendarOpen || root.mediaOpen || root.controlsOpen
        MouseArea { anchors.fill: parent; onClicked: root.closeAll() }
    }

    function closeAll()        { powerOpen = false; calendarOpen = false; mediaOpen = false; controlsOpen = false }
    function togglePower()     { var v = !powerOpen;    closeAll(); powerOpen    = v }
    function toggleCalendar()  { var v = !calendarOpen; closeAll(); calendarOpen = v }
    function toggleMedia()     { var v = !mediaOpen;    closeAll(); mediaOpen    = v }
    function toggleControls()  { var v = !controlsOpen; closeAll(); controlsOpen = v }

    // MPRIS
    property var mprisPlayer: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        return players.length > 0 ? players[0] : null
    }
    property bool   hasMedia:   mprisPlayer !== null
    property string mediaTitle: hasMedia && mprisPlayer.trackTitle ? mprisPlayer.trackTitle : ""

    // Volume (pour l'icône dans la barre)
    property var  pwSink:  Pipewire.defaultAudioSink
    property real vol:     pwSink && pwSink.audio ? pwSink.audio.volume : 0
    property bool muted:   pwSink && pwSink.audio ? pwSink.audio.muted  : false

    Rectangle {
        anchors.fill: parent
        color:        theme.bg

        // Liseré rouge bas
        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 0; color: Qt.rgba(163/255, 35/255, 53/255, 0.55)
        }

        RowLayout {
            anchors.fill:         parent
            anchors.leftMargin:   10
            anchors.rightMargin:  10
            anchors.topMargin:    2
            anchors.bottomMargin: 2
            spacing: 0

            // ══ GAUCHE : icône Arch + workspaces dans conteneur ═══════════
            RowLayout {
                spacing: 6

                // Icône Arch → Rofi
                Rectangle {
                    width: theme.barHeight - 10; height: theme.barHeight - 10; radius: 6
                    color: appMa.containsMouse ? theme.bgHover : Qt.rgba(46/255,37/255,37/255,0.5)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent; text: "󱗼"
                        color: theme.red; font.family: theme.font; font.pixelSize: theme.iconSize + 1
                    }
                    MouseArea {
                        id: appMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.closeAll(); Quickshell.execDetached(["rofi","-show","drun"]) }
                    }
                }

                // Conteneur workspaces
                Rectangle {
                    height: theme.barHeight - 12
                    width:  wsRow.implicitWidth + 12
                    radius: height / 2
                    color:  Qt.rgba(46/255, 37/255, 37/255, 0.6)

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
                                height: theme.barHeight - 12
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width:   parent.width
                                    height:  active ? 6 : (busy ? 4 : 3)
                                    radius:  height / 2
                                    color:   active ? theme.red : (busy ? theme.fgMuted : Qt.rgba(138/255,122/255,136/255,0.4))
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

            // ══ DROITE : icône volume/luminosité + power ══════════════════
            RowLayout {
                spacing: 4

                // Bouton contrôles (volume + luminosité)
                Rectangle {
                    id: ctrlBtn
                    width: theme.barHeight - 10; height: theme.barHeight - 10; radius: 5
                    color: ctrlMa.containsMouse || root.controlsOpen ? theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (root.muted || root.vol < 0.01) return "󰖁"
                            if (root.vol < 0.34) return "󰕿"
                            if (root.vol < 0.67) return "󰖀"
                            return "󰕾"
                        }
                        color: root.controlsOpen ? theme.red : (root.muted ? theme.fgMuted : theme.teal)
                        font.family: theme.font; font.pixelSize: theme.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: ctrlMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleControls()
                        onWheel: wheel => {
                            var d = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                            Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@",d])
                        }
                    }
                }

                // Bouton Power
                Rectangle {
                    width: theme.barHeight - 10; height: theme.barHeight - 10; radius: 5
                    color: pwrMa.containsMouse || root.powerOpen ? theme.red : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent; text: "⏻"
                        color: pwrMa.containsMouse || root.powerOpen ? "#fff" : theme.red
                        font.family: theme.font; font.pixelSize: theme.iconSize
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea { id: pwrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePower() }
                }
            }
        }

        // ══ CENTRE ancré absolument — parfaitement centré sur la barre ════
        // Hors du RowLayout pour un centrage pixel-perfect indépendant des côtés
        Row {
            id: centreBlock
            anchors.centerIn: parent
            spacing: 6

            // Heure + date cliquable
            Rectangle {
                id: clockContainer
                height: theme.barHeight - 6
                width:  clockRow.implicitWidth + 20
                radius: 5
                color:  clockMa.containsMouse || root.calendarOpen ? theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: root.currentTime
                        color: root.calendarOpen ? theme.red : theme.fg
                        font.family: theme.font; font.pixelSize: theme.fontSize; font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Rectangle {
                        width: 1; height: theme.barHeight - 18
                        color: Qt.rgba(138/255,122/255,136/255,0.25)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.currentDate; color: theme.fgMuted
                        font.family: theme.font; font.pixelSize: theme.fontSizeSm
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: clockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleCalendar()
                }
            }

            // Media (si player actif)
            Rectangle {
                visible: root.hasMedia
                height:  theme.barHeight - 8
                width:   mediaTxt.implicitWidth + 24
                radius:  5
                color:   mediaMa.containsMouse || root.mediaOpen ? theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Row {
                    anchors.centerIn: parent; spacing: 5
                    Text {
                        text: "♪"; color: theme.teal
                        font.family: theme.font; font.pixelSize: theme.iconSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: mediaTxt
                        text: root.mediaTitle.length > 28 ? root.mediaTitle.substring(0,25)+"…" : root.mediaTitle
                        color: root.mediaOpen ? theme.fg : theme.fgMuted
                        font.family: theme.font; font.pixelSize: theme.fontSizeSm
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea { id: mediaMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleMedia() }
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
