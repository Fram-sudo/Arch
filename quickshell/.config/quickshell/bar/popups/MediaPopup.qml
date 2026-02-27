// MediaPopup.qml — Contrôle multimédia MPRIS style macOS Tahoe
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

PanelWindow {
    id: win
    property bool open: false

    anchors.top:   true
    anchors.right: true
    margins.top:   Theme.barHeight + 6
    margins.right: 8

    implicitWidth:  300
    property int popupGap: 6
    property int contentH: 180
    implicitHeight: contentH + popupGap

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    // ── Player actif ──────────────────────────────────────────────────────
    property var player: {
        var players = MprisController.players
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackStatus === MprisPlaybackStatus.Playing)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    property bool  isPlaying:  player && player.playbackStatus === MprisPlaybackStatus.Playing
    property string trackTitle:  player && player.trackTitle  ? player.trackTitle  : "Aucun média"
    property string trackArtist: player && player.trackArtists ? player.trackArtists.join(", ") : ""
    property string trackAlbum:  player && player.trackAlbum  ? player.trackAlbum  : ""
    property string artUrl:      player && player.trackArtUrl  ? player.trackArtUrl : ""
    property real   position:    player && player.position     ? player.position    : 0
    property real   length:      player && player.trackLength  ? player.trackLength : 1
    property real   progress:    length > 0 ? Math.min(1.0, position / length) : 0

    // Timer pour mettre à jour la position
    Timer {
        interval: 500; running: win.open && win.isPlaying; repeat: true
        onTriggered: { if (win.player) win.player.updatePosition() }
    }

    function formatTime(ms) {
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: mediaPanel
            width:  parent.width
            height: win.contentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            y: win.open ? win.popupGap : -height - 10
            Behavior on y {
                NumberAnimation {
                    id: slideAnim
                    duration: 320
                    easing.type: win.open ? Easing.OutQuart : Easing.InQuart
                }
            }
            opacity: win.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

            // Fond artwork flouté (si disponible)
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                clip: true

                Image {
                    anchors.fill: parent
                    source: win.artUrl
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.12
                    visible: win.artUrl !== ""
                    layer.enabled: true
                    layer.effect: null // blur workaround
                }
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

            // Contenu
            Item {
                z: 1
                anchors.fill: parent
                anchors.margins: Theme.popupPadding

                Row {
                    id: topRow
                    width: parent.width
                    spacing: 12

                    // Pochette album
                    Rectangle {
                        width: 64; height: 64; radius: 10
                        color: Theme.innerBg
                        border.color: Theme.innerBorder; border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: win.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: win.artUrl !== ""
                        }

                        // Icône fallback
                        Text {
                            anchors.centerIn: parent
                            visible: win.artUrl === ""
                            text: "󰎇"
                            color: Theme.popupFgDim
                            font.family: Theme.fontMono; font.pixelSize: 28
                        }
                    }

                    // Infos piste
                    Column {
                        width: parent.width - 64 - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        // App source
                        Text {
                            text: win.player ? win.player.identity : "Aucun player"
                            color: Theme.red
                            font.family: Theme.font; font.pixelSize: 9
                            font.weight: Font.SemiBold
                        }

                        // Titre
                        Text {
                            text: win.trackTitle
                            color: Theme.popupFg
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                            font.weight: Font.SemiBold
                            width: parent.width; elide: Text.ElideRight
                        }

                        // Artiste
                        Text {
                            text: win.trackArtist
                            color: Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm
                            width: parent.width; elide: Text.ElideRight
                            visible: win.trackArtist !== ""
                        }

                        // Album
                        Text {
                            text: win.trackAlbum
                            color: Theme.popupFgDim
                            font.family: Theme.font; font.pixelSize: Theme.fontSizeXs
                            width: parent.width; elide: Text.ElideRight
                            visible: win.trackAlbum !== ""
                        }
                    }
                }

                // Barre de progression
                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: controlsRow.top
                    anchors.bottomMargin: 10
                    spacing: 4

                    // Track slider
                    Item {
                        width: parent.width; height: 16

                        // Fond track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 3; radius: 2
                            color: Theme.sliderTrack
                        }
                        // Rempli
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * win.progress; height: 3; radius: 2
                            color: Theme.red
                            Behavior on width { NumberAnimation { duration: 400 } }
                        }
                        // Knob
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * win.progress - width/2))
                            width: 10; height: 10; radius: 5
                            color: Theme.sliderKnob
                            Behavior on x { NumberAnimation { duration: 400 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: mouse => {
                                if (win.player && win.length > 0) {
                                    var ratio = Math.max(0, Math.min(1, mouse.x / width))
                                    win.player.position = ratio * win.length
                                }
                            }
                        }
                    }

                    // Temps
                    Row {
                        width: parent.width
                        Text {
                            text: win.formatTime(win.position)
                            color: Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 9
                        }
                        Item { width: 1; implicitWidth: parent.width - posCur.implicitWidth - posTotal.implicitWidth }
                        Text {
                            id: posTotal
                            text: win.formatTime(win.length)
                            color: Theme.popupFgMuted
                            font.family: Theme.font; font.pixelSize: 9
                        }
                    }
                }

                // Boutons de contrôle
                Row {
                    id: controlsRow
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    // Précédent
                    MediaButton {
                        icon: "󰒮"
                        onClicked: { if (win.player) win.player.previous() }
                    }

                    // Play/Pause (plus grand)
                    MediaButton {
                        icon: win.isPlaying ? "󰏤" : "󰐊"
                        size: 38
                        iconSize: 16
                        highlighted: true
                        onClicked: { if (win.player) win.player.togglePlaying() }
                    }

                    // Suivant
                    MediaButton {
                        icon: "󰒭"
                        onClicked: { if (win.player) win.player.next() }
                    }
                }
            }
        }
    }

    // ── Composant MediaButton ─────────────────────────────────────────────
    component MediaButton: Rectangle {
        id: mbtn
        property string icon: ""
        property int    size: 32
        property int    iconSize: 13
        property bool   highlighted: false

        signal clicked()

        width: size; height: size; radius: size / 2
        color: highlighted
               ? (mbtnMa.containsMouse ? Theme.redBright : Theme.red)
               : (mbtnMa.containsMouse ? Theme.glassHover : Theme.innerBg)
        border.color: highlighted ? "transparent" : Theme.innerBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            anchors.centerIn: parent; text: mbtn.icon
            color: mbtn.highlighted ? "#fff" : Theme.popupFg
            font.family: Theme.fontMono; font.pixelSize: mbtn.iconSize
        }
        MouseArea {
            id: mbtnMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: mbtn.clicked()
        }
    }
}
