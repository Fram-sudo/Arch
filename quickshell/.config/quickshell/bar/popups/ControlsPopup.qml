// ControlsPopup.qml — Widget volume + luminosité
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs

PanelWindow {
    id: win
    property bool open:        false
    property int  buttonRightX: 0

    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight + 4
    margins.right: screen ? screen.width - buttonRightX : 4

    implicitWidth:  220
    implicitHeight: brightnessAvailable ? 112 : 68

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

    // Luminosité via brightnessctl
    property bool brightnessAvailable: true
    property real brightness: 0.5

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "g"]
        running: win.open
        stdout: StdioCollector {
            onStreamFinished: {
                var current = parseInt(this.text.trim())
                maxBrightnessProc.running = true
                win._currentBrightness = current
            }
        }
        onExited: code => { if (code !== 0) win.brightnessAvailable = false }
    }

    property int _currentBrightness: 0
    property int _maxBrightness:     100

    Process {
        id: maxBrightnessProc
        command: ["brightnessctl", "m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var max = parseInt(this.text.trim())
                if (max > 0) {
                    win._maxBrightness = max
                    win.brightness = win._currentBrightness / max
                }
            }
        }
    }

    function setBrightness(val) {
        brightness = Math.max(0.05, Math.min(1.0, val))
        var pct = Math.round(brightness * 100) + "%"
        Quickshell.execDetached(["brightnessctl", "s", pct])
    }

    Rectangle {
        anchors.fill: parent
        radius:       Theme.popupRadius
        color:        Theme.bgPopup
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.45)
        border.width: 1
        opacity:      win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Column {
            anchors.fill:    parent
            anchors.margins: 14
            spacing:         14

            // ── Volume ────────────────────────────────────────────────────
            Row {
                width:  parent.width
                height: 20
                spacing: 10

                property var  sink:  Pipewire.defaultAudioSink
                property real vol:   sink && sink.audio ? sink.audio.volume : 0
                property bool muted: sink && sink.audio ? sink.audio.muted  : false

                // Icône volume (clic = mute)
                Text {
                    text: {
                        if (parent.muted || parent.vol < 0.01) return "󰖁"
                        if (parent.vol < 0.34) return "󰕿"
                        if (parent.vol < 0.67) return "󰖀"
                        return "󰕾"
                    }
                    color:  parent.muted ? Theme.fgMuted : Theme.teal
                    font.family: Theme.font; font.pixelSize: Theme.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
                    }
                }

                // Barre de progression cliquable
                Item {
                    width:  parent.width - 36 - 10
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Theme.bgHover
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width:  Math.max(4, parent.width * (parent.parent.muted ? 0 : parent.parent.vol))
                        height: 4; radius: 2
                        color:  parent.parent.muted ? Theme.fgDim : Theme.teal
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            var v = mouse.x / width
                            Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(v*100)+"%"])
                        }
                        onPositionChanged: mouse => {
                            if (pressed) {
                                var v = Math.max(0, Math.min(1, mouse.x / width))
                                Quickshell.execDetached(["wpctl","set-volume","-l","1","@DEFAULT_AUDIO_SINK@", Math.round(v*100)+"%"])
                            }
                        }
                    }
                }

                // Valeur
                Text {
                    text:  Math.round(parent.vol * 100) + "%"
                    color: Theme.fgMuted; font.family: Theme.font; font.pixelSize: 10
                    width: 26; horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: parent.muted ? 0.35 : 1.0
                }
            }

            // ── Luminosité ────────────────────────────────────────────────
            Row {
                visible: win.brightnessAvailable
                width:   parent.width
                height:  20
                spacing: 10

                Text {
                    text:  "󰃞"
                    color: Theme.gold
                    font.family: Theme.font; font.pixelSize: Theme.iconSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width:  parent.width - 36 - 10
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Theme.bgHover
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width:  Math.max(4, parent.width * win.brightness)
                        height: 4; radius: 2
                        color:  Theme.gold
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => win.setBrightness(mouse.x / width)
                        onPositionChanged: mouse => {
                            if (pressed) win.setBrightness(mouse.x / width)
                        }
                    }
                }

                Text {
                    text:  Math.round(win.brightness * 100) + "%"
                    color: Theme.fgMuted; font.family: Theme.font; font.pixelSize: 10
                    width: 26; horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
