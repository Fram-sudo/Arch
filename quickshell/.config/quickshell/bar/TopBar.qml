// TopBar.qml — Barre style macOS Tahoe
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
    property int    batteryPercent: 100
    property bool   batteryCharging: false
    property string batteryStatus: "Full"

    // ── Popups ────────────────────────────────────────────────────────────
    property bool calendarOpen: false
    property bool qsOpen:       false
    property bool mediaOpen:    false
    property bool powerOpen:    false

    function closeAll()       { calendarOpen = false; qsOpen = false; mediaOpen = false; powerOpen = false }
    function toggleCalendar() { var v = !calendarOpen; closeAll(); calendarOpen = v }
    function toggleQs()       { var v = !qsOpen;       closeAll(); qsOpen       = v }
    function toggleMedia()    { var v = !mediaOpen;    closeAll(); mediaOpen    = v }
    function togglePower()    { var v = !powerOpen;    closeAll(); powerOpen    = v }

    // ── Popups ─────────────────────────────────────────────────────────────
    CalendarPopup {
        id: calendarWin; screen: root.screen
        open: root.calendarOpen; onOpenChanged: root.calendarOpen = open
        clockCenterX: clockRect.visible ? clockRect.mapToItem(null, clockRect.width / 2, 0).x : (root.screen ? root.screen.width / 2 : 0)
        onCloseRequested: root.calendarOpen = false
    }
    QuickSettings {
        id: qsWin; screen: root.screen
        open: root.qsOpen; onOpenChanged: root.qsOpen = open
        onCloseRequested: root.qsOpen = false
    }
    // Centres X des boutons (calculés après rendu via Component.onCompleted + timer)
    property int mediaBtnCenterX: root.screen ? root.screen.width / 2 + 60 : 0
    property int powerBtnCenterX: root.screen ? root.screen.width - 22 : 0

    Timer {
        interval: 100; running: true; repeat: false
        onTriggered: {
            var pt1 = mediaBtn.mapToGlobal(mediaBtn.width / 2, 0)
            root.mediaBtnCenterX = pt1.x
            var pt2 = powerBtn.mapToGlobal(powerBtn.width / 2, 0)
            root.powerBtnCenterX = pt2.x
        }
    }

    MediaPopup {
        id: mediaWin; screen: root.screen
        open: root.mediaOpen; onOpenChanged: root.mediaOpen = open
        onCloseRequested: root.mediaOpen = false
        mediaCenterX: root.mediaBtnCenterX
    }
    PowerMenu {
        id: powerWin; screen: root.screen
        open: root.powerOpen; onOpenChanged: root.powerOpen = open
        onCloseRequested: root.powerOpen = false
        buttonCenterX: root.powerBtnCenterX
    }

    // ── Volume Pipewire ───────────────────────────────────────────────────
    property var  pwSink: Pipewire.defaultAudioSink
    property real vol:    pwSink && pwSink.audio ? pwSink.audio.volume : 0
    property bool muted:  pwSink && pwSink.audio ? pwSink.audio.muted  : false

    // ── Détection média via playerctl (compatible Firefox/instances) ──────
    property bool hasMedia:   false
    property bool isPlayingMedia: false

    Process {
        id: mediaCheckProc
        command: ["playerctl", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                var names = this.text.trim().split("\n").filter(n => n.length > 0)
                root.hasMedia = names.length > 0
                if (names.length > 0) statusCheckProc.running = true
                else root.isPlayingMedia = false
            }
        }
    }
    Process {
        id: statusCheckProc
        command: ["playerctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isPlayingMedia = this.text.trim() === "Playing"
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: mediaCheckProc.running = true
    }

    // ── Fond barre ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.barBg
        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

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
                    iconColor: Theme.barFg
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
                                    color:  active ? Theme.barWs : (busy ? Theme.barWsBusy : Theme.barWsEmpty)
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

            // ══ CENTRE — Horloge fixe, média ancré à droite en absolu ════
            Item {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                implicitWidth:  clockRect.width
                implicitHeight: Theme.barHeight

                // Horloge — toujours centrée
                Rectangle {
                    id: clockRect
                    anchors.centerIn: parent
                    width:  clockRow.implicitWidth + 24
                    height: Theme.barHeight - 6
                    radius: 5
                    color: (clockMa.containsMouse || root.calendarOpen)
                           ? Theme.barHover : "transparent"
                    border.color: (clockMa.containsMouse || root.calendarOpen)
                                  ? Theme.barHoverBorder : "transparent"
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Row {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: root.currentTime
                            color: Theme.barFg
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 1; height: Theme.barHeight - 14
                            color: Theme.barSeparator
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.currentDate
                            color: Theme.barFg
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: clockMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleCalendar()
                    }
                }

                // Bouton média — ancré à droite de l'horloge, se décale seul
                Item {
                    id: mediaBtn
                    anchors.left:           clockRect.right
                    anchors.leftMargin:     4
                    anchors.verticalCenter: parent.verticalCenter
                    width:  root.isPlayingMedia ? 38 : Theme.barHeight - 10
                    height: Theme.barHeight
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width:  parent.width + 2
                        height: Theme.barHeight - 6
                        radius: 5
                        color: mediaMa.containsMouse ? Theme.barHover : "transparent"
                        border.color: mediaMa.containsMouse ? Theme.barHoverBorder : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰎇"
                        color: Theme.barFg
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.iconSize
                        opacity: root.isPlayingMedia ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    Row {
                        id: visualizer
                        anchors.centerIn: parent
                        spacing: 2
                        opacity: root.isPlayingMedia ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }

                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                required property int index
                                width:  2.5
                                radius: 1.5
                                color:  Theme.barFg
                                anchors.verticalCenter: parent.verticalCenter
                                property real minH: 2
                                property real maxH: [10, 14, 16, 12, 8][index]
                                height: minH
                                SequentialAnimation on height {
                                    running: root.isPlayingMedia
                                    loops:   Animation.Infinite
                                    PauseAnimation { duration: [0, 140, 60, 200, 100][index] }
                                    NumberAnimation { to: [maxH*0.9,maxH,maxH*0.7,maxH*0.85,maxH][index];       duration: [180,220,160,200,170][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: [minH+2,minH,minH+3,minH+1,minH+4][index];            duration: [140,180,130,160,120][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: [maxH*0.6,maxH*0.8,maxH,maxH*0.5,maxH*0.9][index];   duration: [200,150,210,170,190][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: [minH+1,minH+3,minH,minH+2,minH][index];              duration: [160,130,150,140,180][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: [maxH*0.75,maxH*0.5,maxH*0.85,maxH,maxH*0.6][index]; duration: [190,210,175,185,155][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: minH; duration: [130,150,140,160,120][index]; easing.type: Easing.InOutSine }
                                }
                                NumberAnimation on height {
                                    running: !root.isPlayingMedia
                                    to: 2; duration: 300; easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: mediaMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.toggleMedia()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ══ DROITE ════════════════════════════════════════════════════
            RowLayout {
                spacing: 2

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    height: Theme.barHeight
                    width:  batIndicator.implicitWidth + 16

                    Rectangle {
                        anchors.centerIn: parent
                        width:  parent.width
                        height: Theme.barHeight - 6
                        radius: 5
                        color:        batHoverMa.containsMouse ? Theme.barHover : "transparent"
                        border.color: batHoverMa.containsMouse ? Theme.barHoverBorder : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }

                    BatteryIndicator {
                        id: batIndicator
                        anchors.centerIn: parent
                        percent:  root.batteryPercent
                        charging: root.batteryCharging
                    }

                    MouseArea {
                        id: batHoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                BarButton {
                    icon: "󰍜"
                    iconColor: Theme.barFg
                    active: root.qsOpen
                    onClicked: root.toggleQs()
                }

                BarButton {
                    icon: Theme.isDark ? "󰖔" : "󰖙"
                    iconColor: Theme.barFg
                    active: false
                    onClicked: Theme.toggleTheme()
                }

                // Bouton Power — tout à droite
                Item {
                    id: powerBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width:  Theme.barHeight - 10
                    height: Theme.barHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width:  parent.width
                        height: Theme.barHeight - 6
                        radius: 5
                        color:        powerMa.containsMouse || root.powerOpen ? Theme.barHover : "transparent"
                        border.color: powerMa.containsMouse || root.powerOpen ? Theme.barHoverBorder : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:  "󰐥"
                        color: Theme.barFg
                        font.family:    Theme.fontMono
                        font.pixelSize: Theme.iconSize
                    }

                    MouseArea {
                        id: powerMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePower()
                    }
                }
            }
        }
    }


    // ── Composant BarButton ───────────────────────────────────────────────
    component BarButton: Item {
        id: btn
        property string icon: ""
        property color  iconColor: Theme.barFg
        property bool   active: false
        signal clicked()
        signal wheelUp()
        signal wheelDown()

        implicitWidth:  Theme.barHeight + 2
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.centerIn: parent
            width:  parent.implicitWidth - 4
            height: Theme.barHeight - 6
            radius: 5
            color:       "transparent"
            border.color: (btnMa.containsMouse || btn.active)
                          ? Theme.barHoverBorder
                          : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 100 } }

            // Fond très légèrement teinté au hover
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: (btnMa.containsMouse || btn.active)
                       ? Theme.barHover
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

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

        // Couleur selon niveau
        property color fillColor: {
            if (charging)       return "#4CAF50"
            if (percent > 30)   return "#4CAF50"
            if (percent > 15)   return Theme.gold
            return Theme.red
        }
        // En light : texte % toujours vert gras pour lisibilite
        property color textColor: Theme.isDark ? fillColor : "#4CAF50"

        implicitWidth:  batBody.width + 5 + batPct.width
        implicitHeight: Theme.barHeight

        // ── Corps de la batterie (horizontal) ────────────────────────────
        Item {
            id: batBody
            anchors.verticalCenter: parent.verticalCenter
            width:  22
            height: 11

            // Contour
            Rectangle {
                anchors.left:   parent.left
                anchors.top:    parent.top
                anchors.bottom: parent.bottom
                width: 20
                radius: 2.5
                color:  "transparent"
                border.color: Theme.isDark
                               ? Qt.rgba(bat.fillColor.r, bat.fillColor.g, bat.fillColor.b, 0.55)
                               : Qt.rgba(0, 0, 0, 0.75)
                border.width: 1.5
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Remplissage intérieur
                Rectangle {
                    anchors.left:    parent.left
                    anchors.top:     parent.top
                    anchors.bottom:  parent.bottom
                    anchors.margins: 2
                    width: Math.max(2, (parent.width - 4) * (bat.percent / 100))
                    radius: 1.5
                    color: bat.fillColor
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 400 } }
                }

                // Éclair de charge (centré sur le corps)
                Text {
                    anchors.centerIn: parent
                    visible: bat.charging
                    text: "⚡"
                    font.pixelSize: 7
                    color: "#fff"
                    style: Text.Outline
                    styleColor: Qt.rgba(0,0,0,0.4)
                }
            }

            // Borne positive (petit rectangle à droite)
            Rectangle {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                width:  2.5
                height: 5
                radius: 1
                color:  Theme.isDark
                        ? Qt.rgba(bat.fillColor.r, bat.fillColor.g, bat.fillColor.b, 0.55)
                        : Qt.rgba(0, 0, 0, 0.75)
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        // Pourcentage — badge pill coloré (dark & light)
        Rectangle {
            id: batPct
            anchors.left:           batBody.right
            anchors.leftMargin:     5
            anchors.verticalCenter: parent.verticalCenter
            width:  batPctText.implicitWidth + 8
            height: 14
            radius: 4
            color:  bat.fillColor
            Behavior on color { ColorAnimation { duration: 400 } }

            Text {
                id: batPctText
                anchors.centerIn: parent
                text:  bat.percent + "%"
                color: "#000000"
                font.family:    Theme.font
                font.pixelSize: Theme.fontSizeXs
                font.weight:    Font.Bold
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
