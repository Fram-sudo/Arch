// DashPage.qml — Page 1 : Dashboard (horloge, infos système, média)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Item {
    id: root
    property bool active: false

    // ── Données ───────────────────────────────────────────────────────────
    property string currentTime:    "00:00"
    property string currentTimePm:  "AM"
    property string currentDate:    "lun, 1 jan"
    property string uptime:         "—"
    property string hostname:       "—"
    property string kernel:         "—"

    property string cpuUsage:       "0"
    property string cpuTemp:        "—"
    property string ramUsed:        "0"
    property string ramTotal:       "0"
    property real   ramPercent:     0
    property string diskUsed:       "0"
    property string diskTotal:      "0"
    property real   diskPercent:    0
    property string wifiSsid:       "—"
    property string localIp:        "—"

    // Média
    property string mediaTitle:     ""
    property string mediaArtist:    ""
    property string mediaArtUrl:    ""
    property string mediaPlayer:    ""
    property bool   mediaPlaying:   false
    property bool   hasMedia:       false

    // ── Timers ────────────────────────────────────────────────────────────
    Timer {
        interval: 1000; running: root.active; repeat: true; triggeredOnStart: true
        onTriggered: { timeProc.running = true; dateProc.running = true }
    }
    Timer {
        interval: 3000; running: root.active; repeat: true; triggeredOnStart: true
        onTriggered: { sysProc.running = true; mediaProc.running = true }
    }

    // ── Processus ─────────────────────────────────────────────────────────
    Process {
        id: timeProc
        command: ["date", "+%I:%M|%p"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split("|")
                root.currentTime   = p[0]
                root.currentTimePm = p[1] || "AM"
            }
        }
    }
    Process {
        id: dateProc
        command: ["date", "+%a, %-e %b"]
        stdout: StdioCollector {
            onStreamFinished: root.currentDate = this.text.trim()
        }
    }

    Process {
        id: sysProc
        command: ["bash", "-c", [
            "echo UPTIME:$(uptime -p | sed 's/up //')",
            "echo HOST:$(hostname)",
            "echo KERNEL:$(uname -r)",
            "echo CPU:$(grep -m1 'cpu ' /proc/stat | awk '{u=$2+$3+$4; t=$2+$3+$4+$5+$6+$7+$8; print int(u*100/t)}')",
            "echo CPUTEMP:$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk '{printf \"%.0f\", $1/1000}')",
            "echo RAM:$(free -m | awk '/Mem/{printf \"%d|%d|%.0f\", $3, $2, $3/$2*100}')",
            "echo DISK:$(df -BG / | awk 'NR==2{gsub(/G/,\"\",$3); gsub(/G/,\"\",$2); printf \"%d|%d|%.0f\", $3, $2, $3/$2*100}')",
            "echo WIFI:$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)",
            "echo IP:$(ip route get 1 2>/dev/null | awk '{print $7; exit}')"
        ].join(";")]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    if (l.startsWith("UPTIME:"))  root.uptime     = l.substring(7)
                    if (l.startsWith("HOST:"))    root.hostname   = l.substring(5)
                    if (l.startsWith("KERNEL:"))  root.kernel     = l.substring(7)
                    if (l.startsWith("CPU:"))     root.cpuUsage   = l.substring(4)
                    if (l.startsWith("CPUTEMP:")) root.cpuTemp    = l.substring(8) + "°C"
                    if (l.startsWith("RAM:")) {
                        var r = l.substring(4).split("|")
                        root.ramUsed    = r[0]; root.ramTotal = r[1]
                        root.ramPercent = parseFloat(r[2]) / 100
                    }
                    if (l.startsWith("DISK:")) {
                        var d = l.substring(5).split("|")
                        root.diskUsed    = d[0]; root.diskTotal = d[1]
                        root.diskPercent = parseFloat(d[2]) / 100
                    }
                    if (l.startsWith("WIFI:")) root.wifiSsid = l.substring(5) || "—"
                    if (l.startsWith("IP:"))   root.localIp  = l.substring(3) || "—"
                }
            }
        }
    }

    Process {
        id: mediaProc
        command: ["bash", "-c",
            "P=$(playerctl -l 2>/dev/null | head -1); " +
            "[ -z \"$P\" ] && exit 0; " +
            "playerctl -p \"$P\" metadata --format '{{playerName}}|{{status}}|{{title}}|{{artist}}|{{mpris:artUrl}}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (!t) { root.hasMedia = false; return }
                var p = t.split("|")
                root.mediaPlayer  = p[0] || ""
                root.mediaPlaying = (p[1] === "Playing")
                root.mediaTitle   = p[2] || ""
                root.mediaArtist  = p[3] || ""
                root.mediaArtUrl  = p[4] || ""
                root.hasMedia     = root.mediaTitle !== ""
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────
    Item {
        anchors.fill:        parent
        anchors.margins:     20
        anchors.topMargin:   16

        // ── Horloge ───────────────────────────────────────────────────────
        Column {
            id: clockCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            spacing: 0

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Text {
                    text: root.currentTime
                    color: Theme.popupFg
                    font.family:    Theme.font
                    font.pixelSize: 72
                    font.weight:    Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.currentTimePm
                    color: Theme.red
                    font.family:    Theme.font
                    font.pixelSize: 20
                    font.weight:    Font.Bold
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  root.currentDate
                color: Theme.popupFgMuted
                font.family:    Theme.font
                font.pixelSize: 15
                font.weight:    Font.Medium
            }

            // Hostname + uptime
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                topPadding: 4

                Text {
                    text: "󰌢  " + root.hostname
                    color: Theme.popupFgDim
                    font.family:    Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                }
                Text {
                    text: "  " + root.uptime
                    color: Theme.popupFgDim
                    font.family:    Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                }
                Text {
                    text: "󰌢  " + root.kernel
                    color: Theme.popupFgDim
                    font.family:    Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                }
            }
        }

        // ── Séparateur ────────────────────────────────────────────────────
        Rectangle {
            id: sep
            anchors.top:              clockCol.bottom
            anchors.topMargin:        14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: 1
            color: Theme.separator
        }

        // ── Grille stats + média ──────────────────────────────────────────
        Row {
            anchors.top:     sep.bottom
            anchors.topMargin: 14
            anchors.left:    parent.left
            anchors.right:   parent.right
            spacing: 12

            // ── Grille 2×2 stats ──────────────────────────────────────────
            Grid {
                columns: 2
                rows:    2
                columnSpacing: 10
                rowSpacing:    10
                width: (parent.width - 12 - mediaCard.width)

                // CPU
                StatCard {
                    width: (parent.width - 10) / 2
                    icon:    "󰻠"
                    label:   "CPU"
                    value:   root.cpuUsage + "%"
                    sub:     root.cpuTemp
                    percent: parseFloat(root.cpuUsage) / 100
                }

                // RAM
                StatCard {
                    width: (parent.width - 10) / 2
                    icon:    "󰍛"
                    label:   "RAM"
                    value:   root.ramUsed + " / " + root.ramTotal + " Mo"
                    sub:     Math.round(root.ramPercent * 100) + "%"
                    percent: root.ramPercent
                }

                // Disque
                StatCard {
                    width: (parent.width - 10) / 2
                    icon:    "󰋊"
                    label:   "Disque"
                    value:   root.diskUsed + " / " + root.diskTotal + " Go"
                    sub:     Math.round(root.diskPercent * 100) + "%"
                    percent: root.diskPercent
                }

                // Réseau
                StatCard {
                    width: (parent.width - 10) / 2
                    icon:    "󰤨"
                    label:   "Réseau"
                    value:   root.wifiSsid
                    sub:     root.localIp
                    percent: -1
                }
            }

            // ── Carte média ───────────────────────────────────────────────
            Rectangle {
                id: mediaCard
                width:  220
                height: (parent.height)
                radius: 12
                color:  Theme.innerBg
                border.color: Theme.innerBorder
                border.width: 1
                visible: true

                // Pochette en fond flouté
                Image {
                    anchors.fill: parent
                    source:       root.mediaArtUrl
                    fillMode:     Image.PreserveAspectCrop
                    opacity:      root.hasMedia ? 0.12 : 0
                    smooth:       true
                    visible:      root.mediaArtUrl !== ""
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    width: parent.width - 24

                    // Pochette
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  80; height: 80; radius: 10
                        color:  Qt.rgba(0,0,0,0.3)
                        clip:   true

                        Image {
                            anchors.fill: parent
                            source:  root.mediaArtUrl
                            fillMode: Image.PreserveAspectCrop
                            visible:  root.mediaArtUrl !== "" && status === Image.Ready
                            smooth:   true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.mediaArtUrl === "" || !root.hasMedia
                            text:    root.hasMedia ? "󰎇" : "󰎊"
                            color:   Theme.popupFgMuted
                            font.family:    Theme.fontMono
                            font.pixelSize: 32
                        }
                    }

                    // Titre + artiste
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:  root.hasMedia ? root.mediaTitle : "Aucun média"
                        color: Theme.popupFg
                        font.family:    Theme.font
                        font.pixelSize: 12
                        font.weight:    Font.SemiBold
                        width:          parent.width
                        elide:          Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.hasMedia && root.mediaArtist !== ""
                        text:    root.mediaArtist
                        color:   Theme.popupFgMuted
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSizeXs
                        width:          parent.width
                        elide:          Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Boutons play/pause + prev/next
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14
                        visible: root.hasMedia

                        Repeater {
                            model: [
                                { icon: "󰒮", cmd: "previous" },
                                { icon: root.mediaPlaying ? "󰏤" : "󰐊", cmd: "play-pause" },
                                { icon: "󰒭", cmd: "next" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                property bool isMain: modelData.cmd === "play-pause"
                                width:  isMain ? 36 : 28
                                height: isMain ? 36 : 28
                                radius: height / 2
                                color:  ma.containsMouse
                                        ? (isMain ? Theme.redBright : Theme.glassHover)
                                        : (isMain ? Theme.red       : "transparent")
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent
                                    text:  parent.modelData.icon
                                    color: parent.isMain ? "#fff" : Theme.popupFg
                                    font.family:    Theme.fontMono
                                    font.pixelSize: parent.isMain ? 14 : 12
                                }
                                MouseArea {
                                    id: ma; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["playerctl", parent.modelData.cmd])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Composant StatCard ────────────────────────────────────────────────
    component StatCard: Rectangle {
        property string icon:    ""
        property string label:   ""
        property string value:   ""
        property string sub:     ""
        property real   percent: 0   // -1 = pas de barre

        height: 88
        radius: 12
        color:  Theme.innerBg
        border.color: Theme.innerBorder
        border.width: 1

        Column {
            anchors.left:    parent.left
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: 12
            spacing: 4

            Row {
                spacing: 6
                Text {
                    text:  icon
                    color: Theme.red
                    font.family:    Theme.fontMono
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:  label
                    color: Theme.popupFgMuted
                    font.family:    Theme.font
                    font.pixelSize: Theme.fontSizeXs
                    font.weight:    Font.SemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text:  value
                color: Theme.popupFg
                font.family:    Theme.font
                font.pixelSize: 12
                font.weight:    Font.Medium
                width:          parent.width
                elide:          Text.ElideRight
            }

            Text {
                text:  sub
                color: Theme.popupFgMuted
                font.family:    Theme.font
                font.pixelSize: Theme.fontSizeXs
            }

            // Barre de progression
            Rectangle {
                visible: percent >= 0
                width:   parent.width
                height:  4
                radius:  2
                color:   Theme.sliderTrack

                Rectangle {
                    width:   Math.max(4, parent.width * percent)
                    height:  parent.height
                    radius:  parent.radius
                    color:   percent > 0.85 ? Theme.red
                            : percent > 0.60 ? Theme.gold
                            : Theme.teal
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 300 } }
                }
            }
        }
    }
}
