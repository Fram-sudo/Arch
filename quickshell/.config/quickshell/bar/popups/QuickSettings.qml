// QuickSettings.qml — Panneau rapide : réseau, volume, luminosité, micro, profil énergie
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

PanelWindow {
    id: win
    property bool open: false

    // Positionné à droite, aligné avec le bouton power (même logique que PowerMenu)
    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight + 4
    margins.right: 4

    implicitWidth:  280
    implicitHeight: contentCol.implicitHeight + 2 * Theme.popupPadding + 4

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

    // ═══════════════════════════════════════════════════════════════════════
    // ══ DONNÉES ════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════

    // ── Volume ────────────────────────────────────────────────────────────
    property var  sink:    Pipewire.defaultAudioSink
    property real vol:     sink && sink.audio ? sink.audio.volume : 0
    property bool muted:   sink && sink.audio ? sink.audio.muted  : false

    // ── Micro ─────────────────────────────────────────────────────────────
    property var  source:    Pipewire.defaultAudioSource
    property bool micMuted:  source && source.audio ? source.audio.muted : true

    // ── Luminosité ────────────────────────────────────────────────────────
    property bool brightnessAvailable: true
    property real brightness: 0.5
    property int  _curBright: 0
    property int  _maxBright: 100

    Process {
        id: bGetProc; command: ["brightnessctl", "g"]
        running: win.open
        stdout: StdioCollector {
            onStreamFinished: {
                win._curBright = parseInt(this.text.trim())
                bMaxProc.running = true
            }
        }
        onExited: code => { if (code !== 0) win.brightnessAvailable = false }
    }
    Process {
        id: bMaxProc; command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = parseInt(this.text.trim())
                if (m > 0) { win._maxBright = m; win.brightness = win._curBright / m }
            }
        }
    }
    function setBrightness(val) {
        brightness = Math.max(0.05, Math.min(1.0, val))
        Quickshell.execDetached(["brightnessctl", "s", Math.round(brightness * 100) + "%"])
    }

    // ── Réseau (nmcli) ───────────────────────────────────────────────────
    property string wifiStatus: "disabled"
    property string wifiSsid:  ""
    property string ethStatus: "unavailable"
    property string btStatus:  "no"

    Process {
        id: netProc
        command: ["bash", "-c",
            "echo WIFI:$(nmcli -t -f WIFI g 2>/dev/null || echo unavailable);" +
            "echo SSID:$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2);" +
            "echo ETH:$(nmcli -t -f TYPE,STATE dev 2>/dev/null | grep '^ethernet' | head -1 | cut -d: -f2);" +
            "echo BT:$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}' || echo no)"
        ]
        running: win.open
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    if (l.startsWith("WIFI:"))  win.wifiStatus = l.substring(5).trim().toLowerCase()
                    if (l.startsWith("SSID:"))  win.wifiSsid   = l.substring(5).trim()
                    if (l.startsWith("ETH:"))   win.ethStatus  = l.substring(4).trim().toLowerCase()
                    if (l.startsWith("BT:"))    win.btStatus   = l.substring(3).trim().toLowerCase()
                }
            }
        }
    }

    // ── Power profile ────────────────────────────────────────────────────
    property string powerProfile: "balanced"
    property bool   powerProfileAvailable: true

    Process {
        id: ppGetProc
        command: ["powerprofilectl", "get"]
        running: win.open
        stdout: StdioCollector {
            onStreamFinished: win.powerProfile = this.text.trim().toLowerCase()
        }
        onExited: code => { if (code !== 0) win.powerProfileAvailable = false }
    }

    // Rafraîchissement périodique
    Timer {
        interval: 3000; running: win.open; repeat: true
        onTriggered: { netProc.running = true; if (win.brightnessAvailable) bGetProc.running = true }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ RENDU ══════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════

    Rectangle {
        anchors.fill: parent
        radius:       Theme.popupRadius
        color:        Theme.popupBg
        border.color: Theme.popupBorder
        border.width: Theme.popupBorderWidth

        opacity: win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.popupAnimNormal } }

        // Glossy
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
            id: contentCol
            z: 1
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.popupPadding
            spacing: 10

            // ══════════════════════════════════════════════════════════════
            // ── VOLUME ───────────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Row {
                width: parent.width; height: 22; spacing: 8

                Text {
                    text: {
                        if (win.muted || win.vol < 0.01) return "󰖁"
                        if (win.vol < 0.34) return "󰕿"
                        if (win.vol < 0.67) return "󰖀"
                        return "󰕾"
                    }
                    color: win.muted ? Theme.popupFgMuted : Theme.teal
                    font.family: Theme.font; font.pixelSize: Theme.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
                    }
                }

                Item {
                    width: parent.width - 16 - 34 - 16; height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Theme.popupInnerBg
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(4, parent.width * (win.muted ? 0 : win.vol))
                        height: 4; radius: 2
                        color: win.muted ? Theme.popupFgDim : Theme.teal
                        Behavior on width { NumberAnimation { duration: Theme.popupAnimFast } }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - 8, parent.width * (win.muted ? 0 : win.vol) - 4))
                        width: 8; height: 8; radius: 4
                        color: win.muted ? Theme.popupFgDim : Theme.teal
                        Behavior on x { NumberAnimation { duration: Theme.popupAnimFast } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(mouse.x / width * 100)+"%"])
                        }
                        onPositionChanged: mouse => {
                            if (pressed) {
                                var v = Math.max(0, Math.min(1, mouse.x / width))
                                Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(v*100)+"%"])
                            }
                        }
                    }
                }

                Text {
                    text: Math.round(win.vol * 100) + "%"
                    color: Theme.popupFgMuted; font.family: Theme.font; font.pixelSize: 10
                    width: 34; horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: win.muted ? 0.35 : 1.0
                }
            }

            // ══════════════════════════════════════════════════════════════
            // ── LUMINOSITÉ ───────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Row {
                visible: win.brightnessAvailable
                width: parent.width; height: 22; spacing: 8

                Text {
                    text: "󰃞"; color: Theme.gold
                    font.family: Theme.font; font.pixelSize: Theme.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                }

                Item {
                    width: parent.width - 16 - 34 - 16; height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Theme.popupInnerBg
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(4, parent.width * win.brightness)
                        height: 4; radius: 2; color: Theme.gold
                        Behavior on width { NumberAnimation { duration: Theme.popupAnimFast } }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - 8, parent.width * win.brightness - 4))
                        width: 8; height: 8; radius: 4; color: Theme.gold
                        Behavior on x { NumberAnimation { duration: Theme.popupAnimFast } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => win.setBrightness(mouse.x / width)
                        onPositionChanged: mouse => { if (pressed) win.setBrightness(mouse.x / width) }
                    }
                }

                Text {
                    text: Math.round(win.brightness * 100) + "%"
                    color: Theme.popupFgMuted; font.family: Theme.font; font.pixelSize: 10
                    width: 34; horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ══════════════════════════════════════════════════════════════
            // ── SÉPARATEUR ───────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Rectangle { width: parent.width; height: 1; color: Theme.popupSeparator }

            // ══════════════════════════════════════════════════════════════
            // ── TOGGLES RÉSEAU ───────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Row {
                width: parent.width; spacing: 6

                // WiFi
                Rectangle {
                    property bool connected: win.wifiSsid !== ""
                    width: (parent.width - 12) / 3; height: 52; radius: 10
                    color: connected ? Theme.popupAccent
                         : wifiMa.containsMouse ? Theme.popupHover : Theme.popupInnerBg
                    border.color: connected ? Theme.popupAccent : Theme.popupInnerBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.connected ? "󰤨" : "󰤭"
                            color: parent.parent.connected ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 16
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.wifiSsid !== "" ? win.wifiSsid : "WiFi"
                            color: parent.parent.connected ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 9
                            width: parent.parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: wifiMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi",
                            win.wifiStatus === "enabled" ? "off" : "on"])
                    }
                }

                // Ethernet
                Rectangle {
                    property bool connected: win.ethStatus === "connected"
                    width: (parent.width - 12) / 3; height: 52; radius: 10
                    color: connected ? Theme.popupAccent
                         : ethMa.containsMouse ? Theme.popupHover : Theme.popupInnerBg
                    border.color: connected ? Theme.popupAccent : Theme.popupInnerBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰈀"
                            color: parent.parent.connected ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 16
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Ethernet"
                            color: parent.parent.connected ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 9
                        }
                    }
                    MouseArea { id: ethMa; anchors.fill: parent; hoverEnabled: true }
                }

                // Bluetooth
                Rectangle {
                    property bool powered: win.btStatus === "yes"
                    width: (parent.width - 12) / 3; height: 52; radius: 10
                    color: powered ? Theme.popupAccent
                         : btMa.containsMouse ? Theme.popupHover : Theme.popupInnerBg
                    border.color: powered ? Theme.popupAccent : Theme.popupInnerBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.powered ? "󰂯" : "󰂲"
                            color: parent.parent.powered ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 16
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Bluetooth"
                            color: parent.parent.powered ? "#fff" : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        id: btMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bluetoothctl", "power",
                            win.btStatus === "yes" ? "off" : "on"])
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════
            // ── SÉPARATEUR ───────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Rectangle { width: parent.width; height: 1; color: Theme.popupSeparator }

            // ══════════════════════════════════════════════════════════════
            // ── MICRO + POWER PROFILE ────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Row {
                width: parent.width; spacing: 6

                // Micro
                Rectangle {
                    width: (parent.width - 6) / 2; height: 34; radius: 9
                    color: micMa.containsMouse
                           ? (win.micMuted ? Theme.popupHover : Theme.popupAccentBright)
                           : (win.micMuted ? Theme.popupInnerBg : Theme.popupAccent)
                    border.color: win.micMuted ? Theme.popupInnerBorder : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            text: win.micMuted ? "󰍭" : "󰍬"
                            color: win.micMuted ? Theme.popupFgMuted : "#fff"
                            font.family: Theme.font; font.pixelSize: 13
                        }
                        Text {
                            text: win.micMuted ? "Muet" : "Actif"
                            color: win.micMuted ? Theme.popupFgMuted : "#fff"
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                        }
                    }
                    MouseArea {
                        id: micMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SOURCE@","toggle"])
                    }
                }

                // Power Profile
                Rectangle {
                    visible: win.powerProfileAvailable
                    width: (parent.width - 6) / 2; height: 34; radius: 9
                    color: ppMa.containsMouse ? Theme.popupHover : Theme.popupInnerBg
                    border.color: Theme.popupInnerBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            text: win.powerProfile === "performance" ? "󱐋"
                                : win.powerProfile === "power-saver"  ? "󰌪" : "󰗑"
                            color: win.powerProfile === "performance" ? Theme.gold
                                 : win.powerProfile === "power-saver"  ? Theme.teal : Theme.popupFg
                            font.family: Theme.font; font.pixelSize: 13
                        }
                        Text {
                            text: win.powerProfile === "performance" ? "Perf."
                                : win.powerProfile === "power-saver"  ? "Éco." : "Équilibré"
                            color: Theme.popupFg
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                        }
                    }
                    MouseArea {
                        id: ppMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = "balanced"
                            if (win.powerProfile === "balanced")     next = "performance"
                            if (win.powerProfile === "performance")  next = "power-saver"
                            Quickshell.execDetached(["powerprofilectl", "set", next])
                            win.powerProfile = next
                        }
                    }
                }
            }
        }
    }
}
