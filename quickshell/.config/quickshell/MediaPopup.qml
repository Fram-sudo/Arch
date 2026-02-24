// MediaPopup.qml — Lecteur media (MPRIS : Spotify, Deezer, musique locale)
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

PanelWindow {
    id: win
    property bool open: false

    anchors.top:  true
    anchors.left: true
    margins.top:  theme.barHeight + 4
    margins.left: screen ? (screen.width - implicitWidth) / 2 : 0

    implicitWidth:  320
    implicitHeight: 110

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

    Theme { id: theme }

    // Premier player MPRIS actif
    property var player: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    property bool hasPlayer: player !== null
    property bool playing:   hasPlayer && player.playbackState === MprisPlaybackState.Playing

    Rectangle {
        anchors.fill: parent
        radius:       theme.popupRadius
        color:        theme.bgPopup
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.45)
        border.width: 1
        opacity:      win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 140 } }

        // ── Pas de player ─────────────────────────────────────────────────
        Text {
            anchors.centerIn: parent
            visible: !win.hasPlayer
            text:    "Aucun lecteur actif"
            color:   theme.fgMuted
            font.family: theme.font; font.pixelSize: theme.fontSizeSm
            font.italic: true
        }

        // ── Player actif ──────────────────────────────────────────────────
        Row {
            anchors.fill:    parent
            anchors.margins: 12
            spacing:         12
            visible:         win.hasPlayer

            // Pochette
            Rectangle {
                width: 80; height: 80
                radius: 6
                color: theme.bgHover
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill:    parent
                    anchors.margins: 0
                    source:  win.hasPlayer && win.player.artUrl ? win.player.artUrl : ""
                    visible: source !== ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: null
                }

                Text {
                    anchors.centerIn: parent
                    visible: !win.hasPlayer || !win.player.artUrl
                    text:    "♪"
                    color:   theme.fgMuted
                    font.pixelSize: 28
                }
            }

            // Infos + contrôles
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                width:   win.implicitWidth - 80 - 36

                // Titre
                Text {
                    text:  win.hasPlayer && win.player.trackTitle ? win.player.trackTitle : "—"
                    color: theme.fg
                    font.family: theme.font; font.pixelSize: theme.fontSizeSm; font.bold: true
                    width: parent.width; elide: Text.ElideRight
                }

                // Artiste
                Text {
                    text:  win.hasPlayer && win.player.trackArtists
                           ? win.player.trackArtists.join(", ") : "—"
                    color: theme.fgMuted
                    font.family: theme.font; font.pixelSize: theme.fontSizeSm - 1
                    width: parent.width; elide: Text.ElideRight
                }

                // Contrôles
                Row {
                    spacing: 16

                    Repeater {
                        model: [
                            { icon: "⏮", action: "prev"  },
                            { icon: win.playing ? "⏸" : "⏵", action: "play" },
                            { icon: "⏭", action: "next"  }
                        ]
                        delegate: Text {
                            required property var modelData
                            text:  modelData.icon
                            color: ctrlMa.containsMouse ? theme.red : theme.fgMuted
                            font.pixelSize: 18
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea {
                                id: ctrlMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!win.hasPlayer) return
                                    if (modelData.action === "prev")  win.player.previous()
                                    if (modelData.action === "play")  win.player.playPause()
                                    if (modelData.action === "next")  win.player.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
