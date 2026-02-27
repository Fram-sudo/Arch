// TopBar.qml — Barre style macOS Tahoe
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
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
    property int    batteryPercent: 100
    property bool   batteryCharging: false
    property string batteryStatus: "Full"

    // ── Popups ────────────────────────────────────────────────────────────
    property bool calendarOpen: false
    property bool qsOpen:       false
    property bool mediaOpen:    false

    function closeAll()       { calendarOpen = false; qsOpen = false; mediaOpen = false }
    function toggleCalendar() { var v = !calendarOpen; closeAll(); calendarOpen = v }
    function toggleQs()       { var v = !qsOpen;       closeAll(); qsOpen       = v }
    function toggleMedia()    { var v = !mediaOpen;    closeAll(); mediaOpen    = v }

    // ── Overlay fermeture ─────────────────────────────────────────────────
    PanelWindow {
        screen: root.screen
        anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
        color: "transparent"; exclusionMode: ExclusionMode.Ignore; aboveWindows: true
        visible: root.calendarOpen || root.qsOpen || root.mediaOpen
        MouseArea { anchors.fill: parent; onClicked: root.closeAll() }
    }

    // ── Popups ─────────────────────────────────────────────────────────────
    CalendarPopup {
        id: calendarWin; screen: root.screen
        open: root.calendarOpen; onOpenChanged: root.calendarOpen = open
        clockCenterX: root.screen ? root.screen.width / 2 : 0
    }
    QuickSettings {
        id: qsWin; screen: root.screen
        open: root.qsOpen; onOpenChanged: root.qsOpen = open
    }
    MediaPopup {
        id: mediaWin; screen: root.screen
        open: root.mediaOpen; onOpenChanged: root.mediaOpen = open
    }

    // ── Volume Pipewire ───────────────────────────────────────────────────
    property var  pwSink: Pipewire.defaultAudioSink
    property real vol:    pwSink && pwSink.audio ? pwSink.audio.volume : 0
    property bool muted:  pwSink && pwSink.audio ? pwSink.audio.muted  : false

    // ── MPRIS : est-ce qu'un player tourne ? ────────────────────────────
    property var activePlayer: {
        var players = MprisController.players
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackStatus === MprisPlaybackStatus.Playing)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }
    property bool hasMedia: activePlayer !== null

    // ── Fond barre ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.barBg

        // Bordure basse subtile
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.border
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            // ══ GAUCHE ════════════════════════════════════════════════════
            RowLayout {
                spacing: 2

                // Bouton logo Arch → ouvre rofi
                BarButton {
                    icon: "󰣇"
                    iconColor: Theme.red
                    active: false
                    onClicked: {
                        root.closeAll()
                        Quickshell.execDetached(["rofi", "-show", "drun"])
                    }
                }

                // Workspaces
                Item {
                    height: Theme.barHeight
                    width: wsRow.implicitWidth + 16

                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 6
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
                                width: active ? 20 : 7
                                height: Theme.barHeight
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width:  parent.width
                                    height: active ? 5 : (busy ? 3 : 2)
                                    radius: height / 2
                                    color:  active ? Theme.red : (busy ? Theme.fgMuted : Qt.rgba(1,1,1,0.18))
                                    Behavior on width  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on color  { ColorAnimation  { duration: 180 } }
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

            // ══ CENTRE — Horloge ══════════════════════════════════════════
            Item {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                implicitWidth:  clockRow.implicitWidth + 24
                implicitHeight: Theme.barHeight

                Rectangle {
                    anchors.centerIn: parent
                    width:  clockRow.implicitWidth + 24
                    height: Theme.barHeight - 4
                    radius: (Theme.barHeight - 4) / 2
                    color:  clockMa.containsMouse || root.calendarOpen ? Theme.glassHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            text: root.currentTime
                            color: root.calendarOpen ? Theme.red : Theme.fg
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Rectangle {
                            width: 1; height: Theme.barHeight - 14
                            color: Qt.rgba(0.5, 0.5, 0.5, 0.4)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.currentDate
                            color: Theme.fgMuted
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: clockMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleCalendar()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ══ DROITE ════════════════════════════════════════════════════
            RowLayout {
                spacing: 2

                // Contrôle multimédia — visible si player actif
                BarButton {
                    visible: root.hasMedia
                    icon: {
                        if (!root.activePlayer) return "󰎇"
                        return root.activePlayer.playbackStatus === MprisPlaybackStatus.Playing ? "󰎇" : "󰎊"
                    }
                    iconColor: root.mediaOpen ? Theme.red : Theme.fg
                    active: root.mediaOpen
                    onClicked: root.toggleMedia()
                }

                // Batterie
                BatteryIndicator {
                    percent:  root.batteryPercent
                    charging: root.batteryCharging
                }

                // Indicateur volume compact
                BarButton {
                    icon: {
                        if (root.muted || root.vol < 0.01) return "󰖁"
                        if (root.vol < 0.34) return "󰕿"
                        if (root.vol < 0.67) return "󰖀"
                        return "󰕾"
                    }
                    iconColor: root.qsOpen ? Theme.red : Theme.fgMuted
                    active: root.qsOpen
                    onClicked: root.toggleQs()
                    onWheelUp: Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@","3%+"])
                    onWheelDown: Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@","3%-"])
                }

                // Bouton Centre de contrôle (⊞ macOS-like)
                BarButton {
                    icon: "󰍜"
                    iconColor: root.qsOpen ? Theme.red : Theme.fg
                    active: root.qsOpen
                    onClicked: root.toggleQs()
                }

                // Toggle thème
                BarButton {
                    icon: Theme.isDark ? "󰖔" : "󰖙"
                    iconColor: Theme.fgMuted
                    active: false
                    onClicked: Theme.toggleTheme()
                }
            }
        }
    }

    // ── Composant BarButton ───────────────────────────────────────────────
    component BarButton: Item {
        id: btn
        property string icon: ""
        property color  iconColor: Theme.fg
        property bool   active: false
        signal clicked()
        signal wheelUp()
        signal wheelDown()

        implicitWidth:  Theme.barHeight + 2
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.centerIn: parent
            width:  parent.implicitWidth - 4
            height: Theme.barHeight - 4
            radius: 6
            color:  btnMa.containsMouse || btn.active ? Theme.glassHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: btn.icon
                color: btn.iconColor
                font.family: Theme.fontMono
                font.pixelSize: Theme.iconSize + 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
        MouseArea {
            id: btnMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) btn.wheelUp()
                else btn.wheelDown()
            }
        }
    }

    // ── Composant BatteryIndicator ────────────────────────────────────────
    component BatteryIndicator: Item {
        id: bat
        property int  percent:  100
        property bool charging: false

        implicitWidth:  batRow.implicitWidth + 12
        implicitHeight: Theme.barHeight

        property color batColor: {
            if (charging) return "#4CAF50"
            if (percent > 60) return Theme.fg
            if (percent > 30) return Theme.gold
            return Theme.red
        }

        Row {
            id: batRow
            anchors.centerIn: parent
            spacing: 4

            // Icône batterie colorée selon niveau
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (bat.charging) return "󰂄"
                    if (bat.percent > 90) return "󰁹"
                    if (bat.percent > 75) return "󰂀"
                    if (bat.percent > 60) return "󰁿"
                    if (bat.percent > 45) return "󰁾"
                    if (bat.percent > 30) return "󰁽"
                    if (bat.percent > 15) return "󰁺"
                    return "󰁻"
                }
                color: bat.batColor
                font.family: Theme.fontMono
                font.pixelSize: Theme.iconSize + 2
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: bat.percent + "%"
                color: bat.batColor
                font.family: Theme.font
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }
    }

    // ── Lecture batterie ──────────────────────────────────────────────────
    Process {
        id: batProc
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1;" +
            "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                if (lines.length >= 1) root.batteryPercent = parseInt(lines[0]) || 100
                if (lines.length >= 2) {
                    root.batteryStatus = lines[1].trim()
                    root.batteryCharging = (lines[1].trim() === "Charging" || lines[1].trim() === "Full")
                }
            }
        }
    }

    // ── Horloge ───────────────────────────────────────────────────────────
    Process {
        id: timeProc; command: ["date", "+%H:%M"]; running: true
        stdout: StdioCollector { onStreamFinished: root.currentTime = this.text.trim() }
    }
    Process {
        id: dateProc; command: ["date", "+%a %-e %b"]; running: true
        stdout: StdioCollector { onStreamFinished: root.currentDate = this.text.trim().toLowerCase() }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { timeProc.running = true; dateProc.running = true }
    }
    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: batProc.running = true
    }
}
