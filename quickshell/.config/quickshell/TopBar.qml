// TopBar.qml — Barre flottante du haut
// Structure : [Menu | Workspaces]   [Titre fenêtre]   [Volume | Heure Date]
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: root

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    margins.top:   theme.barMargin
    margins.left:  theme.barMargin
    margins.right: theme.barMargin

    implicitHeight: theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    // ── Thème local ───────────────────────────────────────────────────────
    Theme { id: theme }

    // ── Fond arrondi principal ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       theme.barRadius
        color:        theme.bg
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.45)
        border.width: 0 // Epaisseur du contour de la barre

        RowLayout {
            anchors.fill:    parent
            anchors.margins: 4
            spacing:         0

            // ── GAUCHE : bouton Menu + Workspaces ─────────────────────────
            RowLayout {
                spacing: 2

                // Bouton Menu → ouvre Rofi
                Rectangle {
                    id: menuBtn
                    width:  theme.barHeight - 6
                    height: theme.barHeight - 6
                    radius: theme.barRadius - 2
                    color:  menuMa.containsMouse ? theme.red : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text:  "󱗼"
                        color: menuMa.containsMouse ? theme.bg : theme.red
                        font.family:    theme.font
                        font.pixelSize: theme.iconSize + 4
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: menuMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    Quickshell.execDetached(["rofi", "-show", "drun"])
                    }
                }

                // Séparateur fin
                Rectangle {
                    width:  1
                    height: theme.barHeight - 16
                    color:  theme.bgHover
                }

                // Workspaces 1→4
                Repeater {
                    model: 4
                    delegate: Item {
                        id: wsItem
                        required property int index
                        property int  wsId:    index + 1
                        property bool active:  Hyprland.focusedWorkspace !== null
                                               && Hyprland.focusedWorkspace.id === wsId
                        property bool hasWins: {
                            var ws = Hyprland.workspaces.values
                            for (var i = 0; i < ws.length; i++) {
                                if (ws[i].id === wsId) return true
                            }
                            return false
                        }

                        width:  active ? 18 : (hasWins ? 20 : 16)
                        height: theme.barHeight - 10

                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color:  wsItem.active   ? theme.red
                                  : wsItem.hasWins  ? theme.bgHover
                                  :                   "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text:  wsItem.wsId
                                color: wsItem.active  ? theme.bg
                                     : wsItem.hasWins ? theme.fg
                                     :                  theme.fgMuted
                                font.family:    theme.font
                                font.pixelSize: theme.fontSizeSm
                                font.bold:      wsItem.active
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    Hyprland.dispatch("workspace " + wsItem.wsId)
                        }
                    }
                }
            }

            // ── Spacer ────────────────────────────────────────────────────
            Item { Layout.fillWidth: true }

            // ── CENTRE : Titre de la fenêtre active ───────────────────────
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    var tl = Hyprland.focusedToplevel
                    if (!tl || !tl.title) return ""
                    return tl.title.length > 55 ? tl.title.substring(0, 52) + "…" : tl.title
                }
                color: theme.fgMuted
                font.family:    theme.font
                font.pixelSize: theme.fontSizeSm
                font.italic:    true
            }

            // ── Spacer ────────────────────────────────────────────────────
            Item { Layout.fillWidth: true }

            // ── DROITE : Volume + Horloge ─────────────────────────────────
            RowLayout {
                spacing: 10

                // Volume (PipeWire natif)
                RowLayout {
                    id: volWidget
                    spacing: 6
                    property var  sink:   Pipewire.defaultAudioSink
                    property real vol:    sink && sink.audio ? sink.audio.volume : 0
                    property bool muted:  sink && sink.audio ? sink.audio.muted  : false

                    Text {
                        text: {
                            if (volWidget.muted || volWidget.vol < 0.01) return "󰖁"
                            if (volWidget.vol < 0.34) return "󰕿"
                            if (volWidget.vol < 0.67) return "󰖀"
                            return "󰕾"
                        }
                        color: volWidget.muted ? theme.fgMuted : theme.teal
                        font.family:    theme.font
                        font.pixelSize: theme.iconSize
                    }

                    Text {
                        text:    Math.round(volWidget.vol * 100) + "%"
                        color:   theme.fg
                        opacity: volWidget.muted ? 0.35 : 1.0
                        font.family:    theme.font
                        font.pixelSize: theme.fontSizeSm
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Scroll = volume, clic = mute
                    MouseArea {
                        anchors.fill:    parent
                        hoverEnabled:    true
                        acceptedButtons: Qt.LeftButton
                        onClicked:   Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
                        onWheel: wheel => {
                            var d = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                            Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", d])
                        }
                    }
                }

                // Séparateur
                Rectangle {
                    width:  1
                    height: theme.barHeight - 16
                    color:  theme.bgHover
                }

                // Heure
                Text {
                    text:  root.currentTime
                    color: theme.fg
                    font.family:    theme.font
                    font.pixelSize: theme.fontSize
                    font.bold:      true
                }

                // Date
                Text {
                    text:  root.currentDate
                    color: theme.fgMuted
                    font.family:    theme.font
                    font.pixelSize: theme.fontSizeSm
                }
            }

            Item { width: 4 }
        }
    }

    // ── Horloge : mise à jour chaque seconde ──────────────────────────────
    // Pattern officiel Quickshell : StdioCollector + onStreamFinished + Timer relance
    property string currentTime: "00:00"
    property string currentDate: "lun 1 jan"

    Process {
        id: timeProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.currentTime = this.text.trim()
        }
    }

    Process {
        id: dateProc
        command: ["date", "+%a %e %b"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.currentDate = this.text.trim().toLowerCase()
        }
    }

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            timeProc.running = true
            dateProc.running = true
        }
    }
}
