// SystemPage.qml — Page 3 : Specs système complètes
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Item {
    id: root
    property bool active: false

    // ── Données ───────────────────────────────────────────────────────────
    property string cpuModel:    "—"
    property string cpuUsage:    "0"
    property string cpuTemp:     "—"
    property string cpuFreq:     "—"
    property string cpuCores:    "—"
    property string cpuThreads:  "—"

    property string gpuModel:    "—"
    property string gpuUsage:    "0"
    property string gpuTemp:     "—"
    property string gpuVramUsed: "—"
    property string gpuVramTotal:"—"

    property string ramUsed:     "0"
    property string ramTotal:    "0"
    property real   ramPercent:  0
    property string swapUsed:    "0"
    property string swapTotal:   "0"
    property real   swapPercent: 0

    property var    disks:       []

    property string wifiSsid:    "—"
    property string wifiIp:      "—"
    property string wifiRx:      "—"
    property string wifiTx:      "—"

    property string osName:      "—"
    property string kernel:      "—"
    property string uptime:      "—"
    property string wm:          "Hyprland"

    // ── Refresh ───────────────────────────────────────────────────────────
    Timer {
        interval: 4000; running: root.active; repeat: true; triggeredOnStart: true
        onTriggered: sysProc.running = true
    }

    Process {
        id: sysProc
        command: ["bash", "-c", [
            // CPU
            "echo CPUMODEL:$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')",
            "echo CPUUSE:$(grep -m1 'cpu ' /proc/stat | awk '{u=$2+$3+$4;t=$2+$3+$4+$5+$6+$7+$8;print int(u*100/t)}')",
            "echo CPUTEMP:$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk '{printf \"%.0f\", $1/1000}')",
            "echo CPUFREQ:$(grep 'cpu MHz' /proc/cpuinfo | head -1 | awk '{printf \"%.0f\", $4}')",
            "echo CPUCORES:$(grep -c '^processor' /proc/cpuinfo)",
            "echo CPUTHREADS:$(nproc --all)",
            // GPU
            "echo GPUMODEL:$(lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //' | sed 's/ (.*//')",
            "echo GPUTEMP:$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 | awk '{printf \"%.0f\", $1/1000}')",
            // RAM
            "echo MEM:$(free -m | awk '/Mem/{printf \"%d|%d|%.0f\",$3,$2,$3/$2*100}')",
            "echo SWAP:$(free -m | awk '/Swap/{if($2>0)printf \"%d|%d|%.0f\",$3,$2,$3/$2*100; else print \"0|0|0\"}')",
            // Disques
            "echo DISKS:$(df -BG 2>/dev/null | awk 'NR>1 && $6!~/snap/ && $1~/^\\/dev/{gsub(/G/,\"\",$3);gsub(/G/,\"\",$2);printf \"%s|%s|%s|%.0f;\",$6,$3,$2,$3/$2*100}' | sed 's/;$//')",
            // Réseau
            "echo WIFISSID:$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)",
            "echo WIFIIP:$(ip route get 1 2>/dev/null | awk '{print $7;exit}')",
            "echo WIFIRX:$(cat /proc/net/dev 2>/dev/null | awk 'NR>2{if($1!~/lo/){printf \"%.1f KB/s\",$2/1024;exit}}')",
            "echo WIFITX:$(cat /proc/net/dev 2>/dev/null | awk 'NR>2{if($1!~/lo/){printf \"%.1f KB/s\",$10/1024;exit}}')",
            // OS
            "echo OSNAME:$(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')",
            "echo KERNEL:$(uname -r)",
            "echo UPTIME:$(uptime -p | sed 's/up //')"
        ].join(";")]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    var idx = l.indexOf(":")
                    if (idx < 0) continue
                    var key = l.substring(0, idx)
                    var val = l.substring(idx + 1)
                    switch(key) {
                        case "CPUMODEL":  root.cpuModel   = val; break
                        case "CPUUSE":    root.cpuUsage   = val; break
                        case "CPUTEMP":   root.cpuTemp    = val ? val + "°C" : "—"; break
                        case "CPUFREQ":   root.cpuFreq    = val ? val + " MHz" : "—"; break
                        case "CPUCORES":  root.cpuCores   = val; break
                        case "CPUTHREADS":root.cpuThreads = val; break
                        case "GPUMODEL":  root.gpuModel   = val || "—"; break
                        case "GPUTEMP":   root.gpuTemp    = val ? val + "°C" : "—"; break
                        case "MEM": {
                            var r = val.split("|")
                            root.ramUsed = r[0]; root.ramTotal = r[1]; root.ramPercent = parseFloat(r[2])/100
                            break
                        }
                        case "SWAP": {
                            var s = val.split("|")
                            root.swapUsed = s[0]; root.swapTotal = s[1]; root.swapPercent = parseFloat(s[2])/100
                            break
                        }
                        case "DISKS": {
                            var entries = val.split(";").filter(e => e.length > 0)
                            var arr = []
                            for (var j = 0; j < entries.length; j++) {
                                var p = entries[j].split("|")
                                arr.push({ mount: p[0], used: p[1], total: p[2], pct: parseFloat(p[3])/100 })
                            }
                            root.disks = arr
                            break
                        }
                        case "WIFISSID": root.wifiSsid = val || "—"; break
                        case "WIFIIP":   root.wifiIp   = val || "—"; break
                        case "WIFIRX":   root.wifiRx   = val || "—"; break
                        case "WIFITX":   root.wifiTx   = val || "—"; break
                        case "OSNAME":   root.osName   = val || "—"; break
                        case "KERNEL":   root.kernel   = val || "—"; break
                        case "UPTIME":   root.uptime   = val || "—"; break
                    }
                }
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────
    Item {
        anchors.fill:    parent
        anchors.margins: 24
        anchors.topMargin: 16

        Text {
            id: pageTitle
            anchors.top:  parent.top
            anchors.left: parent.left
            text: "Système"
            color: Theme.popupFg
            font.family:    Theme.font
            font.pixelSize: 18
            font.weight:    Font.Bold
        }

        // 3 colonnes
        Row {
            anchors.top:       pageTitle.bottom
            anchors.topMargin: 14
            anchors.left:      parent.left
            anchors.right:     parent.right
            anchors.bottom:    parent.bottom
            spacing: 10

            // ── Colonne 1 : CPU + GPU ──────────────────────────────────────
            Column {
                width: (parent.width - 20) / 3
                height: parent.height
                spacing: 10

                // CPU
                SysBlock {
                    width: parent.width
                    title: "CPU"
                    titleIcon: "󰻠"
                    rows: [
                        { label: "Modèle",     value: root.cpuModel,   full: true },
                        { label: "Usage",      value: root.cpuUsage + "%" },
                        { label: "Temp",       value: root.cpuTemp },
                        { label: "Fréquence",  value: root.cpuFreq },
                        { label: "Cœurs",      value: root.cpuCores },
                        { label: "Threads",    value: root.cpuThreads }
                    ]
                    barPercent: parseFloat(root.cpuUsage) / 100
                }

                // GPU
                SysBlock {
                    width: parent.width
                    title: "GPU"
                    titleIcon: "󰢮"
                    rows: [
                        { label: "Modèle",  value: root.gpuModel,  full: true },
                        { label: "Temp",    value: root.gpuTemp }
                    ]
                    barPercent: -1
                }
            }

            // ── Colonne 2 : Mémoire + Disques ─────────────────────────────
            Column {
                width: (parent.width - 20) / 3
                height: parent.height
                spacing: 10

                // RAM + SWAP
                SysBlock {
                    width: parent.width
                    title: "Mémoire"
                    titleIcon: "󰍛"
                    rows: [
                        { label: "RAM",  value: root.ramUsed  + " / " + root.ramTotal  + " Mo",  bar: root.ramPercent  },
                        { label: "SWAP", value: root.swapUsed + " / " + root.swapTotal + " Mo",  bar: root.swapPercent }
                    ]
                    barPercent: -1
                }

                // Disques
                Rectangle {
                    width:  parent.width
                    height: Math.max(60, 36 + root.disks.length * 44)
                    radius: 12
                    color:  Theme.innerBg
                    border.color: Theme.innerBorder
                    border.width: 1

                    Column {
                        anchors.fill:    parent
                        anchors.margins: 12
                        spacing: 6

                        Row {
                            spacing: 6
                            Text {
                                text: "󰋊"
                                color: Theme.red
                                font.family:    Theme.fontMono
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Disques"
                                color: Theme.popupFgMuted
                                font.family:    Theme.font
                                font.pixelSize: Theme.fontSizeXs
                                font.weight:    Font.SemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Repeater {
                            model: root.disks
                            delegate: Column {
                                required property var modelData
                                width: parent.width
                                spacing: 3

                                Row {
                                    width: parent.width
                                    Text {
                                        text:  modelData.mount
                                        color: Theme.popupFg
                                        font.family:    Theme.fontMono
                                        font.pixelSize: Theme.fontSizeXs
                                        width:          parent.width - pctDisk.width - 4
                                        elide:          Text.ElideMiddle
                                    }
                                    Text {
                                        id: pctDisk
                                        text:  modelData.used + " / " + modelData.total + " Go"
                                        color: Theme.popupFgMuted
                                        font.family:    Theme.font
                                        font.pixelSize: Theme.fontSizeXs
                                    }
                                }
                                Rectangle {
                                    width:  parent.width
                                    height: 4; radius: 2
                                    color:  Theme.sliderTrack
                                    Rectangle {
                                        width:  Math.max(4, parent.width * modelData.pct)
                                        height: parent.height; radius: parent.radius
                                        color:  modelData.pct > 0.85 ? Theme.red
                                               : modelData.pct > 0.60 ? Theme.gold : Theme.teal
                                        Behavior on width { NumberAnimation { duration: 400 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Colonne 3 : Réseau + OS ────────────────────────────────────
            Column {
                width: (parent.width - 20) / 3
                height: parent.height
                spacing: 10

                // Réseau
                SysBlock {
                    width: parent.width
                    title: "Réseau"
                    titleIcon: "󰤨"
                    rows: [
                        { label: "SSID",    value: root.wifiSsid },
                        { label: "IP",      value: root.wifiIp   },
                        { label: "Reçu",    value: root.wifiRx   },
                        { label: "Envoyé",  value: root.wifiTx   }
                    ]
                    barPercent: -1
                }

                // OS
                SysBlock {
                    width: parent.width
                    title: "Système"
                    titleIcon: "󰌢"
                    rows: [
                        { label: "OS",      value: root.osName  },
                        { label: "Kernel",  value: root.kernel  },
                        { label: "Uptime",  value: root.uptime  },
                        { label: "WM",      value: root.wm      }
                    ]
                    barPercent: -1
                }
            }
        }
    }

    // ── Composant SysBlock ────────────────────────────────────────────────
    component SysBlock: Rectangle {
        property string title:       ""
        property string titleIcon:   ""
        property var    rows:        []
        property real   barPercent:  -1  // -1 = pas de barre globale

        height: 36 + rows.length * 22 + (barPercent >= 0 ? 14 : 0) + 16
        radius: 12
        color:  Theme.innerBg
        border.color: Theme.innerBorder
        border.width: 1

        Column {
            anchors.fill:    parent
            anchors.margins: 12
            spacing: 4

            // En-tête
            Row {
                spacing: 6
                Text {
                    text:  titleIcon
                    color: Theme.red
                    font.family:    Theme.fontMono
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:  title
                    color: Theme.popupFgMuted
                    font.family:    Theme.font
                    font.pixelSize: Theme.fontSizeXs
                    font.weight:    Font.SemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Barre globale
            Rectangle {
                visible: barPercent >= 0
                width:   parent.width
                height:  4; radius: 2
                color:   Theme.sliderTrack
                Rectangle {
                    width:  Math.max(4, parent.width * barPercent)
                    height: parent.height; radius: parent.radius
                    color:  barPercent > 0.85 ? Theme.red
                           : barPercent > 0.60 ? Theme.gold : Theme.teal
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }

            // Lignes de données
            Repeater {
                model: rows
                delegate: Item {
                    required property var modelData
                    width:  parent.width
                    height: modelData.full ? 32 : 20

                    Column {
                        anchors.fill: parent
                        visible:      modelData.full === true
                        Text {
                            text:  parent.parent.modelData.value
                            color: Theme.popupFg
                            font.family:    Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            width:          parent.width
                            elide:          Text.ElideRight
                            wrapMode:       Text.WordWrap
                            maximumLineCount: 2
                        }
                    }

                    Row {
                        anchors.fill:  parent
                        visible:       !modelData.full
                        Text {
                            text:  parent.parent.modelData.label + ":"
                            color: Theme.popupFgMuted
                            font.family:    Theme.font
                            font.pixelSize: Theme.fontSizeXs
                            width:          80
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 80
                            spacing: 2
                            Text {
                                text:  parent.parent.parent.modelData.value
                                color: Theme.popupFg
                                font.family:    Theme.fontMono
                                font.pixelSize: Theme.fontSizeXs
                                width:          parent.width
                                elide:          Text.ElideRight
                            }
                            Rectangle {
                                visible: parent.parent.parent.modelData.bar !== undefined
                                width:   parent.width
                                height:  3; radius: 1.5
                                color:   Theme.sliderTrack
                                Rectangle {
                                    property real p: parent.parent.parent.parent.modelData.bar || 0
                                    width:  Math.max(3, parent.width * p)
                                    height: parent.height; radius: parent.radius
                                    color:  p > 0.85 ? Theme.red : p > 0.60 ? Theme.gold : Theme.teal
                                    Behavior on width { NumberAnimation { duration: 400 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
