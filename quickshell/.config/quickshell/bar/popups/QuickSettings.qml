// QuickSettings.qml — Panneau rapide redesigné style glassmorphism
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

PanelWindow {
    id: win
    property bool open: false

    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight
    margins.right: 4

    property int popupGap: 10
    property int popupContentH: contentCol.implicitHeight + 2 * Theme.popupPadding + 4

    implicitWidth:  300
    implicitHeight: popupContentH + popupGap

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || qsSlideAnim.running

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
    // ══ COMPOSANT SLIDER RÉUTILISABLE ════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════
    component QsSlider: Item {
        id: slider
        property string icon: ""
        property color  iconColor: Theme.popupFg
        property real   value: 0
        property bool   isMuted: false
        property string percentText: Math.round(value * 100) + "%"

        signal clicked()
        signal sliderMoved(real newVal)

        width: parent.width; height: 28

        // Icône cliquable
        Rectangle {
            id: sliderIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26; radius: 7
            color: sliderIconMa.containsMouse ? Theme.glassHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

            Text {
                anchors.centerIn: parent; text: slider.icon
                color: slider.isMuted ? Theme.popupFgMuted : slider.iconColor
                font.family: Theme.font; font.pixelSize: Theme.iconSize
            }
            MouseArea {
                id: sliderIconMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: slider.clicked()
            }
        }

        // Barre de slider
        Item {
            id: sliderTrack
            anchors.left: sliderIcon.right; anchors.leftMargin: 8
            anchors.right: sliderPercent.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20

            // Track fond
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: Theme.sliderHeight; radius: Theme.sliderRadius
                color: Theme.sliderTrack
            }
            // Track rempli
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(Theme.sliderHeight, parent.width * (slider.isMuted ? 0 : slider.value))
                height: Theme.sliderHeight; radius: Theme.sliderRadius
                color: slider.isMuted ? Theme.popupFgDim : Theme.sliderFill
                Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }
            // Knob
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width, parent.width * (slider.isMuted ? 0 : slider.value) - width / 2))
                width: Theme.sliderKnobSize; height: Theme.sliderKnobSize; radius: Theme.sliderKnobSize / 2
                color: slider.isMuted ? Theme.popupFgDim : Theme.sliderKnob
                Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: mouse => slider.sliderMoved(Math.max(0, Math.min(1, mouse.x / width)))
                onPositionChanged: mouse => {
                    if (pressed) slider.sliderMoved(Math.max(0, Math.min(1, mouse.x / width)))
                }
            }
        }

        // Pourcentage
        Text {
            id: sliderPercent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: slider.percentText
            color: Theme.popupFgMuted; font.family: Theme.font; font.pixelSize: 10
            width: 34; horizontalAlignment: Text.AlignRight
            opacity: slider.isMuted ? 0.4 : 1.0
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ COMPOSANT TOGGLE PILL RÉUTILISABLE ═══════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════
    component TogglePill: Rectangle {
        id: pill
        property bool   active: false
        property string icon: ""
        property string label: ""
        property bool   hasArrow: false

        signal clicked()

        height: 48; radius: Theme.toggleRadius
        color: active
               ? (pillMa.containsMouse ? Theme.toggleActiveBorder : Theme.toggleActiveBg)
               : (pillMa.containsMouse ? Theme.popupHover : Theme.toggleInactiveBg)
        border.color: active ? Theme.toggleActiveBorder : Theme.toggleInactiveBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.popupAnimFast } }

        Row {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: pill.icon
                color: pill.active ? "#fff" : Theme.popupFgMuted
                font.family: Theme.font; font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
            }
            Text {
                text: pill.label
                color: pill.active ? "#fff" : Theme.popupFgMuted
                font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                anchors.verticalCenter: parent.verticalCenter
                width: pill.width - 12 - 15 - 8 - (pill.hasArrow ? 24 : 0) - 12
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
            }
        }

        // Flèche droite
        Text {
            visible: pill.hasArrow
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "›"; color: pill.active ? Qt.rgba(1,1,1,0.7) : Theme.popupFgDim
            font.family: Theme.font; font.pixelSize: 16; font.bold: true
            Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
        }

        MouseArea {
            id: pillMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ RENDU ══════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════

    // ── Masque : clippe le popup quand il glisse sous la barre ─────────
    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: qsPanel
            width: parent.width
            height: win.popupContentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            // Position Y animée : glisse de sous la barre jusqu'au gap
            y: win.open ? win.popupGap : -height
            Behavior on y { NumberAnimation { id: qsSlideAnim; duration: 300; easing.type: Easing.OutQuart } }

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
            spacing: 12

            // ══════════════════════════════════════════════════════════════
            // ── VOLUME SLIDER ────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            QsSlider {
                icon: {
                    if (win.muted || win.vol < 0.01) return "󰖁"
                    if (win.vol < 0.34) return "󰕿"
                    if (win.vol < 0.67) return "󰖀"
                    return "󰕾"
                }
                iconColor: Theme.teal
                value: win.vol
                isMuted: win.muted
                onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
                onSliderMoved: newVal => Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(newVal * 100)+"%"])
            }

            // ══════════════════════════════════════════════════════════════
            // ── LUMINOSITÉ SLIDER ────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            QsSlider {
                visible: win.brightnessAvailable
                icon: "󰃞"
                iconColor: Theme.gold
                value: win.brightness
                isMuted: false
                onClicked: {} // pas de toggle
                onSliderMoved: newVal => win.setBrightness(newVal)
            }

            // ══════════════════════════════════════════════════════════════
            // ── SÉPARATEUR ───────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Rectangle { width: parent.width; height: 1; color: Theme.popupSeparator }

            // ══════════════════════════════════════════════════════════════
            // ── GRILLE TOGGLES (2×2) ─────────────────────────────────────
            // ══════════════════════════════════════════════════════════════

            // Ligne 1 : WiFi + Bluetooth
            Row {
                width: parent.width; spacing: 6
                TogglePill {
                    width: (parent.width - 6) / 2
                    active: win.wifiSsid !== ""
                    icon: win.wifiSsid !== "" ? "󰤨" : "󰤭"
                    label: win.wifiSsid !== "" ? win.wifiSsid : "WiFi"
                    hasArrow: true
                    onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi",
                        win.wifiStatus === "enabled" ? "off" : "on"])
                }
                TogglePill {
                    width: (parent.width - 6) / 2
                    active: win.btStatus === "yes"
                    icon: win.btStatus === "yes" ? "󰂯" : "󰂲"
                    label: "Bluetooth"
                    hasArrow: true
                    onClicked: Quickshell.execDetached(["bluetoothctl", "power",
                        win.btStatus === "yes" ? "off" : "on"])
                }
            }

            // Ligne 2 : Power Profile + Ethernet
            Row {
                width: parent.width; spacing: 6
                TogglePill {
                    visible: win.powerProfileAvailable
                    width: (parent.width - 6) / 2
                    active: win.powerProfile === "performance"
                    icon: win.powerProfile === "performance" ? "󱐋"
                        : win.powerProfile === "power-saver"  ? "󰌪" : "󰗑"
                    label: win.powerProfile === "performance" ? "Perf."
                        : win.powerProfile === "power-saver"  ? "Éco." : "Équilibré"
                    hasArrow: true
                    onClicked: {
                        var next = "balanced"
                        if (win.powerProfile === "balanced")     next = "performance"
                        if (win.powerProfile === "performance")  next = "power-saver"
                        Quickshell.execDetached(["powerprofilectl", "set", next])
                        win.powerProfile = next
                    }
                }
                TogglePill {
                    width: (parent.width - 6) / 2
                    active: win.ethStatus === "connected"
                    icon: "󰈀"
                    label: "Ethernet"
                    hasArrow: false
                }
            }

            // ══════════════════════════════════════════════════════════════
            // ── SÉPARATEUR ───────────────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Rectangle { width: parent.width; height: 1; color: Theme.popupSeparator }

            // ══════════════════════════════════════════════════════════════
            // ── MICRO + NOTIFICATIONS ────────────────────────────────────
            // ══════════════════════════════════════════════════════════════
            Row {
                width: parent.width; spacing: 6

                // Micro
                Rectangle {
                    width: (parent.width - 6) / 2; height: 36; radius: 10
                    color: micMa.containsMouse
                           ? (win.micMuted ? Theme.popupHover : Theme.toggleActiveBorder)
                           : (win.micMuted ? Theme.toggleInactiveBg : Theme.toggleActiveBg)
                    border.color: win.micMuted ? Theme.toggleInactiveBorder : "transparent"
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

                // Notifications (placeholder — DND toggle)
                Rectangle {
                    width: (parent.width - 6) / 2; height: 36; radius: 10
                    property bool dnd: false
                    color: dndMa.containsMouse ? Theme.popupHover : Theme.toggleInactiveBg
                    border.color: Theme.toggleInactiveBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            text: parent.parent.dnd ? "󰂛" : "󰂚"
                            color: parent.parent.dnd ? Theme.red : Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 13
                        }
                        Text {
                            text: parent.parent.dnd ? "Silencieux" : "Notifs"
                            color: Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                        }
                    }
                    MouseArea {
                        id: dndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.dnd = !parent.dnd
                    }
                }
            }
        }
    }
}
}