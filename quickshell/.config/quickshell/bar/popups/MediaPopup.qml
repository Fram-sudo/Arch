// MediaPopup.qml — Lecteur media (MPRIS)
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

PanelWindow {
    id: win
    property bool open: false

    anchors.top:  true
    anchors.left: true
    margins.top:  Theme.barHeight + 4
    margins.left: screen ? (screen.width - implicitWidth) / 2 : 0

    implicitWidth:  320
    implicitHeight: 110

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

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
        radius:       Theme.popupRadius
        color:        Theme.popupBg
        border.color: Theme.popupBorder
        border.width: Theme.popupBorderWidth

        opacity: win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.popupAnimNormal } }

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

        // Pas de player
        Text {
            z: 1; anchors.centerIn: parent
            visible: !win.hasPlayer
            text: "Aucun lecteur actif"
            color: Theme.popupFgMuted
            font.family: Theme.font; font.pixelSize: Theme.fontSizeSm; font.italic: true
        }

        // Player actif
        Row {
            z: 1
            anchors.fill: parent; anchors.margins: 12
            spacing: 12; visible: win.hasPlayer

            Rectangle {
                width: 80; height: 80; radius: 10
                color: Theme.popupInnerBg
                border.color: Theme.popupInnerBorder; border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: win.hasPlayer && win.player.artUrl ? win.player.artUrl : ""
                    visible: source !== ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true; layer.effect: null
                }
                Text {
                    anchors.centerIn: parent
                    visible: !win.hasPlayer || !win.player.artUrl
                    text: "♪"; color: Theme.popupFgMuted; font.pixelSize: 28
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6; width: win.implicitWidth - 80 - 36

                Text {
                    text: win.hasPlayer && win.player.trackTitle ? win.player.trackTitle : "—"
                    color: Theme.popupFg
                    font.family: Theme.font; font.pixelSize: Theme.fontSizeSm; font.bold: true
                    width: parent.width; elide: Text.ElideRight
                }
                Text {
                    text: win.hasPlayer && win.player.trackArtists ? win.player.trackArtists.join(", ") : "—"
                    color: Theme.popupFgMuted
                    font.family: Theme.font; font.pixelSize: Theme.fontSizeSm - 1
                    width: parent.width; elide: Text.ElideRight
                }

                Row {
                    spacing: 16
                    Repeater {
                        model: [
                            { icon: "⏮", action: "prev" },
                            { icon: win.playing ? "⏸" : "⏵", action: "play" },
                            { icon: "⏭", action: "next" }
                        ]
                        delegate: Text {
                            required property var modelData
                            text: modelData.icon
                            color: ctrlMa.containsMouse ? Theme.popupAccentBright : Theme.popupFgMuted
                            font.pixelSize: 18
                            Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                            MouseArea {
                                id: ctrlMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!win.hasPlayer) return
                                    if (modelData.action === "prev") win.player.previous()
                                    if (modelData.action === "play") win.player.playPause()
                                    if (modelData.action === "next") win.player.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
