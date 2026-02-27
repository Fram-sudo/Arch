// MediaPopup.qml — Contrôle média via playerctl (contourne bug Quickshell/Firefox)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win
    property bool open: false

    property int mediaCenterX: win.width / 2

    signal closeRequested()

    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    property int panelWidth:  280
    property int panelTop:    Theme.barHeight + 6
    property int panelLeft:   Math.min(Math.max(8, mediaCenterX - panelWidth / 2), win.width - panelWidth - 8)
    property int contentH:    playerCol.implicitHeight + 2 * Theme.popupPadding

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

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    // ── Données récupérées via playerctl ──────────────────────────────────
    // Liste des players : [ { name, status, title, artist, artUrl, length, position } ]
    property var players: []

    // Rafraîchissement
    Timer {
        id: refreshTimer
        interval: 2000
        running: win.open
        repeat: true
        triggeredOnStart: true
        onTriggered: listProc.running = true
    }

    // Étape 1 : récupère la liste des players
    Process {
        id: listProc
        command: ["playerctl", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                var names = this.text.trim().split("\n").filter(n => n.length > 0)
                if (names.length === 0) {
                    win.players = []
                    return
                }
                metaModel.clear()
                for (var i = 0; i < names.length; i++) {
                    metaModel.append({ playerName: names[i] })
                }
                metaFetcher.currentIndex = 0
                metaFetcher.fetchNext()
            }
        }
    }

    // Modèle temporaire pour itérer sur les players
    ListModel { id: metaModel }

    // Étape 2 : récupère les métadonnées de chaque player l'un après l'autre
    QtObject {
        id: metaFetcher
        property int currentIndex: 0
        property var collected: []

        function fetchNext() {
            if (currentIndex >= metaModel.count) {
                // Merge intelligent : ne remplace que si différent
                var prev = win.players
                var next = collected
                var changed = prev.length !== next.length
                if (!changed) {
                    for (var i = 0; i < next.length; i++) {
                        if (!prev[i] ||
                            prev[i].name     !== next[i].name   ||
                            prev[i].status   !== next[i].status ||
                            prev[i].title    !== next[i].title  ||
                            prev[i].artist   !== next[i].artist ||
                            Math.abs((prev[i].position||0) - (next[i].position||0)) > 2000000) {
                            changed = true
                            break
                        }
                    }
                }
                if (changed) win.players = next
                return
            }
            var name = metaModel.get(currentIndex).playerName
            metaProc.playerName = name
            metaProc.command = ["playerctl", "-p", name,
                "metadata", "--format",
                "{{status}}|{{title}}|{{artist}}|{{mpris:artUrl}}|{{mpris:length}}|{{position}}"]
            metaProc.running = true
        }
    }

    Process {
        id: metaProc
        property string playerName: ""
        stdout: StdioCollector {
            onStreamFinished: {
                var raw   = this.text.trim()
                var parts = raw.split("|")
                var entry = {
                    name:     metaProc.playerName,
                    status:   parts[0] || "Stopped",
                    title:    parts[1] || "",
                    artist:   parts[2] || "",
                    artUrl:   parts[3] || "",
                    length:   parseInt(parts[4]) || 0,
                    position: parseInt(parts[5]) || 0
                }
                metaFetcher.collected = metaFetcher.collected.concat([entry])
                metaFetcher.currentIndex++
                metaFetcher.fetchNext()
            }
        }
        onExited: code => {
            if (code !== 0) {
                metaFetcher.currentIndex++
                metaFetcher.fetchNext()
            }
        }
    }

    // Reset collected à chaque refresh
    Connections {
        target: listProc
        function onRunningChanged() {
            if (listProc.running) metaFetcher.collected = []
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    function formatTime(us) {
        if (!us || us <= 0) return "0:00"
        var s = Math.floor(us / 1000000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function serviceInfo(playerName) {
        var n = playerName.toLowerCase()
        if (n.indexOf("spotify")   !== -1) return { icon: "󰓇", color: "#1DB954", label: "Spotify"   }
        if (n.indexOf("deezer")    !== -1) return { icon: "󰓇", color: "#A238FF", label: "Deezer"    }
        if (n.indexOf("vlc")       !== -1) return { icon: "󰕼", color: "#FF8800", label: "VLC"       }
        if (n.indexOf("mpv")       !== -1) return { icon: "󰐊", color: "#6A9FB5", label: "mpv"       }
        if (n.indexOf("rhythmbox") !== -1) return { icon: "󰝚", color: "#E84393", label: "Rhythmbox" }
        if (n.indexOf("firefox")   !== -1) return { icon: "󰈹", color: "#FF7139", label: "Firefox"   }
        if (n.indexOf("chromium")  !== -1) return { icon: "󰊯", color: "#4285F4", label: "Chromium"  }
        if (n.indexOf("chrome")    !== -1) return { icon: "󰊯", color: "#4285F4", label: "Chrome"    }
        return { icon: "󰎇", color: Theme.red, label: playerName }
    }

    // ── Rendu ─────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        Rectangle {
            id: mediaPanel
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

            layer.enabled: !Theme.isDark
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset:  Theme.popupShadowX
                verticalOffset:    Theme.popupShadowY
                radius:            Theme.popupShadowRadius
                samples:           32
                color:             Qt.rgba(0, 0, 0, Theme.popupShadowOpacity)
            }

            // Glossy
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: parent.height * Theme.popupGlossHeight; radius: parent.radius; z: 0
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.popupGlossTop }
                    GradientStop { position: 1.0; color: Theme.popupGlossBottom }
                }
            }

            Column {
                id: playerCol
                z: 1
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: Theme.popupPadding
                spacing: 8

                // Aucun player
                Item {
                    width: parent.width; height: 36
                    visible: win.players.length === 0
                    Text {
                        anchors.centerIn: parent
                        text: "Aucun média en cours"
                        color: Theme.popupFgMuted
                        font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                    }
                }

                // Un item par player
                Repeater {
                    model: win.players

                    delegate: Item {
                        required property var modelData
                        property var p:   modelData
                        property var svc: win.serviceInfo(p.name)
                        property bool playing: p.status === "Playing"
                        property real prog: p.length > 0 ? Math.min(1, p.position / p.length) : 0

                        width: parent.width
                        height: itemCol.implicitHeight + 16

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Theme.innerBg
                            border.color: Theme.innerBorder; border.width: 1
                            clip: true

                            // Fond artwork flouté
                            Image {
                                anchors.fill: parent
                                source: p.artUrl
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0.15
                                visible: p.artUrl !== ""
                                smooth: true
                            }

                            Column {
                                id: itemCol
                                anchors.left:    parent.left
                                anchors.right:   parent.right
                                anchors.top:     parent.top
                                anchors.margins: 8
                                spacing: 6

                                // Ligne principale : pochette | infos | play/pause
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    // Pochette / logo
                                    Rectangle {
                                        width: 44; height: 44; radius: 7
                                        color: Qt.rgba(0,0,0,0.3)
                                        clip: true
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            anchors.fill: parent
                                            source: p.artUrl
                                            fillMode: Image.PreserveAspectCrop
                                            visible: p.artUrl !== "" && status === Image.Ready
                                            smooth: true
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: p.artUrl === ""
                                            text: svc.icon
                                            color: svc.color
                                            font.family: Theme.fontMono; font.pixelSize: 22
                                        }
                                    }

                                    // Infos
                                    Column {
                                        width: parent.width - 44 - 36 - 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        // Badge service
                                        Row {
                                            spacing: 3
                                            Text {
                                                text: svc.icon; color: svc.color
                                                font.family: Theme.fontMono; font.pixelSize: 9
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: svc.label; color: svc.color
                                                font.family: Theme.font; font.pixelSize: 9
                                                font.weight: Font.SemiBold
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Text {
                                            text: p.title || "—"
                                            color: Theme.popupFg
                                            font.family: Theme.font; font.pixelSize: 12
                                            font.weight: Font.SemiBold
                                            width: parent.width; elide: Text.ElideRight
                                        }
                                        Text {
                                            visible: p.artist !== ""
                                            text: p.artist
                                            color: Theme.popupFgMuted
                                            font.family: Theme.font; font.pixelSize: Theme.fontSizeXs
                                            width: parent.width; elide: Text.ElideRight
                                        }
                                    }

                                    // Bouton play/pause
                                    Rectangle {
                                        width: 32; height: 32; radius: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: ppMa.containsMouse
                                               ? Qt.lighter(svc.color, 1.2) : svc.color
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: playing ? "󰏤" : "󰐊"
                                            color: "#fff"
                                            font.family: Theme.fontMono; font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: ppMa; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: Quickshell.execDetached(
                                                ["playerctl", "-p", p.name, "play-pause"])
                                        }
                                    }
                                }

                                // Barre de progression
                                Item {
                                    width: parent.width; height: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width; height: 3; radius: 2
                                        color: Theme.sliderTrack
                                    }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(3, parent.width * prog)
                                        height: 3; radius: 2
                                        color: svc.color
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: mouse => {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                            var pos   = Math.round(ratio * p.length)
                                            Quickshell.execDetached(
                                                ["playerctl", "-p", p.name,
                                                 "position", String(Math.round(pos / 1000000))])
                                        }
                                    }
                                }

                                // Temps
                                Row {
                                    width: parent.width
                                    Text {
                                        text: win.formatTime(p.position)
                                        color: Theme.popupFgDim
                                        font.family: Theme.font; font.pixelSize: 9
                                    }
                                    Item { width: parent.width - tl.implicitWidth - tr.implicitWidth; id: tl }
                                    Text {
                                        id: tr
                                        text: win.formatTime(p.length)
                                        color: Theme.popupFgDim
                                        font.family: Theme.font; font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}