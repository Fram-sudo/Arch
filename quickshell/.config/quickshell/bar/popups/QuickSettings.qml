// QuickSettings.qml — Centre de contrôle style macOS Tahoe
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win
    property bool open: false

    signal closeRequested()

    // Plein écran pour capturer les clics hors popup
    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    property int panelWidth:  300
    property int panelRight:  8
    property int panelTop:    Theme.barHeight + 6
    property int contentH:    0  // sera mis à jour par mainCol
    property int panelHeight: contentH + 2 * Theme.popupPadding

    // MouseArea plein écran — ferme si clic hors du rectangle visuel
    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            var panelX = win.width - win.panelRight - win.panelWidth
            var inPanel = (mouse.x >= panelX &&
                           mouse.x <= panelX + win.panelWidth &&
                           mouse.y >= win.panelTop &&
                           mouse.y <= win.panelTop + win.panelHeight)
            if (!inPanel) win.closeRequested()
        }
        propagateComposedEvents: true
    }

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    // ── Volume ────────────────────────────────────────────────────────────
    property var  sink:   Pipewire.defaultAudioSink
    property real vol:    sink && sink.audio ? sink.audio.volume : 0
    property bool muted:  sink && sink.audio ? sink.audio.muted  : false

    property var  source:   Pipewire.defaultAudioSource
    property bool micMuted: source && source.audio ? source.audio.muted : true

    // ── Luminosité ────────────────────────────────────────────────────────
    property bool brightnessAvailable: true
    property real brightness: 0.5
    property int  _curBright: 0
    property int  _maxBright: 100

    Process {
        id: bGetProc; command: ["brightnessctl", "g"]; running: win.open
        stdout: StdioCollector {
            onStreamFinished: { win._curBright = parseInt(this.text.trim()); bMaxProc.running = true }
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
        Quickshell.execDetached(["brightnessctl","s", Math.round(brightness * 100) + "%"])
    }

    // ── Réseau ────────────────────────────────────────────────────────────
    property string wifiStatus: "disabled"
    property string wifiSsid:   ""
    property string ethStatus:  "unavailable"
    property string btStatus:   "no"

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
                    if (l.startsWith("WIFI:")) win.wifiStatus = l.substring(5).trim().toLowerCase()
                    if (l.startsWith("SSID:")) win.wifiSsid   = l.substring(5).trim()
                    if (l.startsWith("ETH:"))  win.ethStatus  = l.substring(4).trim().toLowerCase()
                    if (l.startsWith("BT:"))   win.btStatus   = l.substring(3).trim().toLowerCase()
                }
            }
        }
    }

    // ── Power profile ─────────────────────────────────────────────────────
    property string powerProfile: "balanced"
    property bool   powerProfileAvailable: true

    Process {
        id: ppGetProc; command: ["powerprofilectl","get"]; running: win.open
        stdout: StdioCollector { onStreamFinished: win.powerProfile = this.text.trim().toLowerCase() }
        onExited: code => { if (code !== 0) win.powerProfileAvailable = false }
    }

    // DND toggle (local, pas connecté à swaync pour le moment)
    property bool dnd: false

    Timer {
        interval: 3000; running: win.open; repeat: true
        onTriggered: { netProc.running = true; if (win.brightnessAvailable) bGetProc.running = true }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ RENDER ═════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════

    Item {
        anchors.fill: parent

        Rectangle {
            id: qsPanel
            x:      win.width - win.panelRight - win.panelWidth
            width:  win.panelWidth
            height: mainCol.implicitHeight + 2 * Theme.popupPadding
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            onHeightChanged: win.contentH = height

            y: win.open ? win.panelTop : win.panelTop - height - 10
            Behavior on y {
                NumberAnimation {
                    id: slideAnim
                    duration: 320
                    easing.type: win.open ? Easing.OutQuart : Easing.InQuart
                }
            }
            opacity: win.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

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
                z: 0
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: parent.height * Theme.popupGlossHeight; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.popupGlossTop }
                    GradientStop { position: 1.0; color: Theme.popupGlossBottom }
                }
            }

            // ── Contenu ────────────────────────────────────────────────────
            Column {
                id: mainCol
                z: 1
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.popupPadding
                spacing: 10

                // ── Titre ──────────────────────────────────────────────────
                Row {
                    width: parent.width
                    Text {
                        text: "Centre de contrôle"
                        color: Theme.popupFg
                        font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.SemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: 1; Layout.fillWidth: true }
                }

                // ── Sliders ────────────────────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: sliderBlock.implicitHeight + 16
                    radius: Theme.popupRadius - 4
                    color: Theme.innerBg
                    border.color: Theme.innerBorder; border.width: 1

                    Column {
                        id: sliderBlock
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 10
                        spacing: 10

                        // Volume
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
                            onSliderMoved: v => Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(v*100)+"%"])
                        }

                        // Séparateur interne
                        Rectangle { width: parent.width; height: 1; color: Theme.separator }

                        // Luminosité
                        QsSlider {
                            visible: win.brightnessAvailable
                            icon: {
                                if (win.brightness < 0.33) return "󰃞"
                                if (win.brightness < 0.66) return "󰃟"
                                return "󰃠"
                            }
                            iconColor: Theme.gold
                            value: win.brightness
                            isMuted: false
                            onClicked: {}
                            onSliderMoved: v => win.setBrightness(v)
                        }
                    }
                }

                // ── Grille toggles 2×2 ────────────────────────────────────
                Grid {
                    width: parent.width
                    columns: 2
                    rows: 2
                    columnSpacing: 6
                    rowSpacing: 6

                    // WiFi
                    TogglePill {
                        width: (parent.width - 6) / 2
                        active: win.wifiSsid !== ""
                        icon: win.wifiSsid !== "" ? "󰤨" : "󰤭"
                        label: win.wifiSsid !== "" ? win.wifiSsid : "Wi-Fi"
                        sublabel: win.wifiSsid !== "" ? "Connecté" : "Désactivé"
                        onClicked: Quickshell.execDetached(["nmcli","radio","wifi",
                            win.wifiStatus === "enabled" ? "off" : "on"])
                    }

                    // Bluetooth
                    TogglePill {
                        width: (parent.width - 6) / 2
                        active: win.btStatus === "yes"
                        icon: win.btStatus === "yes" ? "󰂯" : "󰂲"
                        label: "Bluetooth"
                        sublabel: win.btStatus === "yes" ? "Activé" : "Désactivé"
                        onClicked: Quickshell.execDetached(["bluetoothctl","power",
                            win.btStatus === "yes" ? "off" : "on"])
                    }

                    // Power profile
                    TogglePill {
                        visible: win.powerProfileAvailable
                        width: (parent.width - 6) / 2
                        active: win.powerProfile === "performance"
                        icon: win.powerProfile === "performance" ? "󱐋"
                            : win.powerProfile === "power-saver"  ? "󰌪" : "󰗑"
                        label: win.powerProfile === "performance" ? "Performance"
                            : win.powerProfile === "power-saver"  ? "Économie" : "Équilibré"
                        sublabel: "Profil batterie"
                        onClicked: {
                            var next = "balanced"
                            if (win.powerProfile === "balanced")    next = "performance"
                            if (win.powerProfile === "performance") next = "power-saver"
                            Quickshell.execDetached(["powerprofilectl","set",next])
                            win.powerProfile = next
                        }
                    }

                    // DND
                    TogglePill {
                        width: (parent.width - 6) / 2
                        active: win.dnd
                        icon: win.dnd ? "󰂛" : "󰂚"
                        label: "Ne pas déranger"
                        sublabel: win.dnd ? "Activé" : "Désactivé"
                        onClicked: win.dnd = !win.dnd
                    }
                }

                // ── Micro ─────────────────────────────────────────────────
                Rectangle {
                    width: parent.width; height: 40; radius: 10
                    color: micMa.containsMouse
                           ? (win.micMuted ? Theme.glassHover : Theme.popupAccentBright)
                           : (win.micMuted ? Theme.innerBg    : Theme.popupAccent)
                    border.color: win.micMuted ? Theme.innerBorder : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text {
                            text: win.micMuted ? "󰍭" : "󰍬"
                            color: win.micMuted ? Theme.popupFgMuted : "#fff"
                            font.family: Theme.fontMono; font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: win.micMuted ? "Micro coupé" : "Micro actif"
                            color: win.micMuted ? Theme.popupFgMuted : "#fff"
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: micMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SOURCE@","toggle"])
                    }
                }

                // ── Toggle thème ───────────────────────────────────────────
                Rectangle {
                    width: parent.width; height: 40; radius: 10
                    color: themeMa.containsMouse ? Theme.glassHover : Theme.innerBg
                    border.color: Theme.innerBorder; border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: Theme.isDark ? "󰖔" : "󰖙"
                            color: Theme.popupFg
                            font.family: Theme.fontMono; font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Theme.isDark ? "Passer en clair" : "Passer en sombre"
                            color: Theme.popupFg
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    // Switch visuel
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 20; radius: 10
                        color: Theme.isDark ? Theme.red : Qt.rgba(0,0,0,0.15)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.isDark ? parent.width - width - 3 : 3
                            width: 14; height: 14; radius: 7
                            color: "#fff"
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    }
                    MouseArea {
                        id: themeMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.toggleTheme()
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ COMPOSANT SLIDER ═══════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════
    component QsSlider: Item {
        id: slider
        property string icon: ""
        property color  iconColor: Theme.popupFg
        property real   value: 0
        property bool   isMuted: false

        signal clicked()
        signal sliderMoved(real v)

        width: parent.width; height: 26

        // Icône
        Rectangle {
            id: iconRect
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26; radius: 7
            color: iconMa.containsMouse ? Theme.glassHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Text {
                anchors.centerIn: parent; text: slider.icon
                color: slider.isMuted ? Theme.popupFgMuted : slider.iconColor
                font.family: Theme.fontMono; font.pixelSize: Theme.iconSize
            }
            MouseArea { id: iconMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: slider.clicked() }
        }

        // Track
        Item {
            anchors.left: iconRect.right; anchors.leftMargin: 8
            anchors.right: pctLabel.left; anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            height: 18

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: Theme.sliderHeight; radius: Theme.sliderRadius
                color: Theme.sliderTrack
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(Theme.sliderHeight, parent.width * (slider.isMuted ? 0 : slider.value))
                height: Theme.sliderHeight; radius: Theme.sliderRadius
                color: slider.isMuted ? Theme.popupFgDim : Theme.sliderFill
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width, parent.width * (slider.isMuted ? 0 : slider.value) - width/2))
                width: Theme.sliderKnobSize; height: Theme.sliderKnobSize; radius: Theme.sliderKnobSize/2
                color: slider.isMuted ? Theme.popupFgDim : Theme.sliderKnob
                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: mouse => slider.sliderMoved(Math.max(0, Math.min(1, mouse.x / width)))
                onPositionChanged: mouse => { if (pressed) slider.sliderMoved(Math.max(0, Math.min(1, mouse.x / width))) }
            }
        }

        // Pourcentage
        Text {
            id: pctLabel
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: Math.round(slider.value * 100) + "%"
            color: Theme.popupFgMuted; font.family: Theme.font; font.pixelSize: Theme.fontSizeXs
            width: 32; horizontalAlignment: Text.AlignRight
            opacity: slider.isMuted ? 0.4 : 1.0
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ══ COMPOSANT TOGGLE PILL ══════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════════════
    component TogglePill: Rectangle {
        id: pill
        property bool   active: false
        property string icon: ""
        property string label: ""
        property string sublabel: ""

        signal clicked()

        height: 56; radius: Theme.popupRadius - 4
        color: active
               ? (pillMa.containsMouse ? Theme.toggleActiveBorder : Theme.toggleActiveBg)
               : (pillMa.containsMouse ? Theme.glassHover : Theme.toggleInactive)
        border.color: active ? Theme.toggleActiveBorder : Theme.toggleInactiveBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Column {
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: pill.icon
                color: pill.active ? "#fff" : Theme.popupFgMuted
                font.family: Theme.fontMono; font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
            Text {
                text: pill.label
                color: pill.active ? "#fff" : Theme.popupFg
                font.family: Theme.font; font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                width: pill.width - 20; elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
            Text {
                text: pill.sublabel
                color: pill.active ? Qt.rgba(1,1,1,0.65) : Theme.popupFgMuted
                font.family: Theme.font; font.pixelSize: 9
                width: pill.width - 20; elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        MouseArea {
            id: pillMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}