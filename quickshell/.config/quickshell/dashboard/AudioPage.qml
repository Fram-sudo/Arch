// AudioPage.qml — Page 2 : Contrôle audio complet
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

Item {
    id: root
    property bool active: false

    // ── Pipewire ──────────────────────────────────────────────────────────
    property var  sink:     Pipewire.defaultAudioSink
    property real vol:      sink && sink.audio ? sink.audio.volume : 0
    property bool muted:    sink && sink.audio ? sink.audio.muted  : false
    property var  source:   Pipewire.defaultAudioSource
    property bool micMuted: source && source.audio ? source.audio.muted : true
    property real micVol:   source && source.audio ? source.audio.volume : 0

    // ── Apps audio via wpctl ──────────────────────────────────────────────
    property var appVolumes: []

    Timer {
        interval: 2000; running: root.active; repeat: true; triggeredOnStart: true
        onTriggered: appsProc.running = true
    }

    Process {
        id: appsProc
        command: ["bash", "-c",
            "wpctl status 2>/dev/null | awk '/Streams/,/^$/' | grep -E '\\[vol:' | " +
            "sed 's/.*│//' | sed 's/^[[:space:]]*//' | head -8"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(l => l.length > 0)
                var result = []
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    // Extrait le volume [vol: X.XX]
                    var volMatch = l.match(/\[vol:\s*([\d.]+)/)
                    var vol = volMatch ? parseFloat(volMatch[1]) : 1.0
                    // Nom de l'app : tout ce qui précède le [vol
                    var name = l.replace(/\[vol:.*/, "").replace(/^\d+\.\s*/, "").trim()
                    if (name.length > 0)
                        result.push({ name: name, vol: Math.min(1.0, vol) })
                }
                root.appVolumes = result
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────
    Item {
        anchors.fill:    parent
        anchors.margins: 24

        // Titre de page
        Text {
            id: pageTitle
            anchors.top:  parent.top
            anchors.left: parent.left
            text: "Audio"
            color: Theme.popupFg
            font.family:    Theme.font
            font.pixelSize: 18
            font.weight:    Font.Bold
        }

        // ── Contenu en deux colonnes ──────────────────────────────────────
        Row {
            anchors.top:         pageTitle.bottom
            anchors.topMargin:   16
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.bottom:      parent.bottom
            spacing: 16

            // ── Colonne gauche : sortie + micro ───────────────────────────
            Column {
                width: (parent.width - 16) / 2
                height: parent.height
                spacing: 12

                // Sortie audio
                Rectangle {
                    width:  parent.width
                    height: 130
                    radius: 14
                    color:  Theme.innerBg
                    border.color: Theme.innerBorder
                    border.width: 1

                    Column {
                        anchors.fill:    parent
                        anchors.margins: 14
                        spacing: 10

                        Row {
                            spacing: 8
                            Text {
                                text: root.muted ? "󰖁" : (root.vol < 0.34 ? "󰕿" : root.vol < 0.67 ? "󰖀" : "󰕾")
                                color: Theme.teal
                                font.family:    Theme.fontMono
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Sortie"
                                color: Theme.popupFg
                                font.family:    Theme.font
                                font.pixelSize: 13
                                font.weight:    Font.SemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item { width: 1; Layout.fillWidth: true }
                        }

                        // Nom du sink
                        Text {
                            text: root.sink ? (root.sink.description || root.sink.name || "—") : "—"
                            color: Theme.popupFgMuted
                            font.family:    Theme.font
                            font.pixelSize: Theme.fontSizeXs
                            width:          parent.width
                            elide:          Text.ElideRight
                        }

                        // Slider volume sortie
                        AudioSlider {
                            width:   parent.width
                            value:   root.vol
                            isMuted: root.muted
                            onIconClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
                            onMoved: v => Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(v*100)+"%"])
                        }
                    }
                }

                // Micro
                Rectangle {
                    width:  parent.width
                    height: 130
                    radius: 14
                    color:  Theme.innerBg
                    border.color: Theme.innerBorder
                    border.width: 1

                    Column {
                        anchors.fill:    parent
                        anchors.margins: 14
                        spacing: 10

                        Row {
                            spacing: 8
                            Text {
                                text: root.micMuted ? "󰍭" : "󰍬"
                                color: root.micMuted ? Theme.popupFgMuted : Theme.red
                                font.family:    Theme.fontMono
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Micro"
                                color: Theme.popupFg
                                font.family:    Theme.font
                                font.pixelSize: 13
                                font.weight:    Font.SemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Nom de la source
                        Text {
                            text: root.source ? (root.source.description || root.source.name || "—") : "—"
                            color: Theme.popupFgMuted
                            font.family:    Theme.font
                            font.pixelSize: Theme.fontSizeXs
                            width:          parent.width
                            elide:          Text.ElideRight
                        }

                        // Slider micro
                        AudioSlider {
                            width:   parent.width
                            value:   root.micVol
                            isMuted: root.micMuted
                            accentColor: Theme.red
                            onIconClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SOURCE@","toggle"])
                            onMoved: v => Quickshell.execDetached(["wpctl","set-volume","@DEFAULT_AUDIO_SOURCE@", Math.round(v*100)+"%"])
                        }
                    }
                }
            }

            // ── Colonne droite : volumes par app ──────────────────────────
            Rectangle {
                width:  (parent.width - 16) / 2
                height: parent.height
                radius: 14
                color:  Theme.innerBg
                border.color: Theme.innerBorder
                border.width: 1

                Column {
                    anchors.fill:    parent
                    anchors.margins: 14
                    spacing: 0

                    Text {
                        text: "Volumes par application"
                        color: Theme.popupFgMuted
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSizeXs
                        font.weight:    Font.SemiBold
                        bottomPadding:  10
                    }

                    // Liste des apps
                    Repeater {
                        model: root.appVolumes
                        delegate: Item {
                            required property var modelData
                            width:  parent.width
                            height: 46

                            Column {
                                anchors.fill:        parent
                                anchors.bottomMargin: 6
                                spacing: 4

                                Row {
                                    width: parent.width
                                    Text {
                                        text:  modelData.name
                                        color: Theme.popupFg
                                        font.family:    Theme.font
                                        font.pixelSize: Theme.fontSizeXs
                                        width:          parent.width - pctTxt.width - 4
                                        elide:          Text.ElideRight
                                    }
                                    Text {
                                        id: pctTxt
                                        text:  Math.round(modelData.vol * 100) + "%"
                                        color: Theme.popupFgMuted
                                        font.family:    Theme.font
                                        font.pixelSize: Theme.fontSizeXs
                                    }
                                }

                                Rectangle {
                                    width:  parent.width
                                    height: 4
                                    radius: 2
                                    color:  Theme.sliderTrack
                                    Rectangle {
                                        width:  Math.max(4, parent.width * modelData.vol)
                                        height: parent.height
                                        radius: parent.radius
                                        color:  Theme.teal
                                        Behavior on width { NumberAnimation { duration: 300 } }
                                    }
                                }
                            }
                        }
                    }

                    // Message si vide
                    Text {
                        visible: root.appVolumes.length === 0
                        text:    "Aucune application active"
                        color:   Theme.popupFgMuted
                        font.family:    Theme.font
                        font.pixelSize: Theme.fontSizeSm
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 20
                    }
                }
            }
        }
    }

    // ── Composant AudioSlider ─────────────────────────────────────────────
    component AudioSlider: Item {
        property real  value:       0
        property bool  isMuted:     false
        property color accentColor: Theme.teal

        signal iconClicked()
        signal moved(real v)

        height: 26

        Rectangle {
            id: iconBtn
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26; radius: 7
            color: iconMa.containsMouse ? Theme.glassHover : "transparent"
            Behavior on color { ColorAnimation { duration: 80 } }
            Text {
                anchors.centerIn: parent
                text:  parent.parent.isMuted ? "󰖁" : (parent.parent.accentColor === Theme.red ? "󰍬" : "󰕾")
                color: parent.parent.isMuted ? Theme.popupFgMuted : parent.parent.accentColor
                font.family:    Theme.fontMono
                font.pixelSize: 13
            }
            MouseArea {
                id: iconMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.parent.parent.iconClicked()
            }
        }

        Item {
            anchors.left:           iconBtn.right
            anchors.leftMargin:     8
            anchors.right:          pct.left
            anchors.rightMargin:    6
            anchors.verticalCenter: parent.verticalCenter
            height: 18

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: Theme.sliderHeight; radius: Theme.sliderRadius
                color: Theme.sliderTrack
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:  Math.max(Theme.sliderHeight, parent.width * (parent.parent.parent.isMuted ? 0 : parent.parent.parent.value))
                height: Theme.sliderHeight; radius: Theme.sliderRadius
                color:  parent.parent.parent.isMuted ? Theme.popupFgDim : parent.parent.parent.accentColor
                Behavior on width { NumberAnimation { duration: 80 } }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width,
                    parent.width * (parent.parent.parent.isMuted ? 0 : parent.parent.parent.value) - width/2))
                width: Theme.sliderKnobSize; height: Theme.sliderKnobSize; radius: Theme.sliderKnobSize/2
                color: parent.parent.parent.isMuted ? Theme.popupFgDim : Theme.sliderKnob
                Behavior on x { NumberAnimation { duration: 80 } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked:          mouse => parent.parent.parent.moved(Math.max(0, Math.min(1, mouse.x / width)))
                onPositionChanged:  mouse => { if (pressed) parent.parent.parent.moved(Math.max(0, Math.min(1, mouse.x / width))) }
            }
        }

        Text {
            id: pct
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            text:  Math.round(parent.value * 100) + "%"
            color: Theme.popupFgMuted
            font.family: Theme.font; font.pixelSize: Theme.fontSizeXs
            width: 32; horizontalAlignment: Text.AlignRight
            opacity: parent.isMuted ? 0.4 : 1.0
        }
    }
}
