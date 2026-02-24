// Dock.qml — Dock flottant auto-caché avec animation MacOS
import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    // Hauteur du panneau = hauteur max du dock (icône agrandie) + marge + zone trigger
    property int dockMaxHeight: Math.round((theme.dockHeight - 12) * 1.45) + 12
    implicitHeight: dockMaxHeight + theme.barMargin + 40

    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    color:         "transparent"

    Theme { id: theme }

    // ── État ──────────────────────────────────────────────────────────────
    property bool revealed:      false   // dock en cours de révélation / caché
    property bool fullyRevealed: false   // true seulement après fin d'animation

    // fullyRevealed passe à true après la durée de l'animation de glissement
    onRevealedChanged: {
        if (revealed) {
            fullyRevealTimer.restart()
        } else {
            fullyRevealed = false
        }
    }
    Timer {
        id: fullyRevealTimer
        interval: 300   // légèrement > durée animation (280ms)
        onTriggered: root.fullyRevealed = true
    }

    // ── Zone de détection (toute la largeur de l'écran, bord bas) ────────
    MouseArea {
        id: triggerZone
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height: 40   // zone confortable sur toute la largeur
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            if (containsMouse) {
                hideTimer.stop()
                root.revealed = true
            } else if (!dockSurface.hovered) {
                hideTimer.restart()
            }
        }
    }

    // ── Timer masquage (délai pour éviter le clignotement) ────────────────
    Timer {
        id: hideTimer
        interval: 500
        onTriggered: root.revealed = false
    }

    // ── Applications épinglées ────────────────────────────────────────────
    // Se rendre à l'emplacement /usr/share/icons/Papirus pour trouver le nom de l'icone souhaité, et la remplacé dans la valeur iconName
    property var apps: [
        { name: "Fichiers",     iconName: "org.kde.dolphin",     cmd: ["dolphin"],             wmClass: "dolphin" },
        { name: "Terminal",     iconName: "kitty",               cmd: ["kitty"],               wmClass: "kitty"   },
        { name: "Firefox",      iconName: "firefox",             cmd: ["firefox"],             wmClass: "firefox" }
        
    ]

    // ── Îlot du dock ──────────────────────────────────────────────────────
    Rectangle {
        id: dockBg

        // Taille de base des items
        property int itemSzBase: theme.dockHeight - 12   // ~32px
        property int cnt:        root.apps.length

        // Hauteur = taille max de l'icône agrandie + marge, pour ne pas couper
        width:  cnt * itemSzBase + (cnt - 1) * 6 + 20
        height: Math.round(itemSzBase * 1.45) + 12
        radius: theme.dockRadius
        clip:   false   // les icônes agrandies peuvent dépasser vers le haut

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     root.revealed
                                  ? theme.barMargin
                                  : -(dockBg.height + 4)

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        color:        "transparent"
        border.width: 0

        // HoverHandler détecte le survol du dock sans interférer avec les clics
        // Il fonctionne en parallèle des MouseArea des boutons (pas de vol d'événements)
        HoverHandler {
            id: dockSurface
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop()
                } else if (!triggerZone.containsMouse) {
                    hideTimer.restart()
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     8
            spacing: 6

            Repeater {
                model: root.apps

                delegate: Item {
                    id: dockItem
                    required property var modelData
                    required property int index

                    property bool isOpen: {
                        if (!modelData.wmClass) return false
                        var wins = Hyprland.windows.values
                        for (var i = 0; i < wins.length; i++) {
                            if (wins[i].resourceClass.toLowerCase() ===
                                modelData.wmClass.toLowerCase()) return true
                        }
                        return false
                    }

                    property bool hovered: false

                    // Seule la largeur change → pousse les voisins horizontalement
                    // La hauteur reste fixe, l'icône grandit vers le haut via son ancrage
                    property real targetSize: hovered
                                              ? dockBg.itemSzBase * 1.45
                                              : dockBg.itemSzBase

                    width:  targetSize
                    height: dockBg.itemSzBase   // hauteur fixe, pas d'animation verticale

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    // Icône système — ancrée en bas, grandit vers le haut
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     dockItem.isOpen ? 5 : 2
                        width:  dockItem.targetSize - 8
                        height: dockItem.targetSize - 8
                        source:  Quickshell.iconPath(dockItem.modelData.iconName, true)
                        visible: source !== ""
                        smooth:  true
                        mipmap:  true
                        Behavior on width  { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    // Fallback : initiale si aucune icône trouvée
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        text:    dockItem.modelData.name.charAt(0)
                        color:   theme.fg
                        font.family:    theme.font
                        font.pixelSize: dockItem.targetSize * 0.5
                        font.bold:      true
                        visible: Quickshell.iconPath(dockItem.modelData.iconName, true) === ""
                    }

                    // Pastille rouge = app ouverte
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     1
                        width:  dockItem.isOpen ? 10 : 0
                        height: 3
                        radius: 2
                        color:  "#A32335"
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:    dockItem.hovered = true
                        onExited:     dockItem.hovered = false
                        onClicked:    Quickshell.execDetached(dockItem.modelData.cmd)
                    }
                }
            }
        }
    }
}
