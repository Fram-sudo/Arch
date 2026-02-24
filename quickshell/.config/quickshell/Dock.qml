// Dock.qml — Dock flottant du bas (applications épinglées)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    margins.bottom: theme.dockMargin
    margins.left:   theme.dockMargin
    margins.right:  theme.dockMargin

    implicitHeight: theme.dockHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    Theme { id: theme }

    // Applications épinglées
    // iconName : nom freedesktop — chargé automatiquement depuis le thème système
    // wmClass  : classe WM pour l'indicateur d'app ouverte (vide = pas d'indicateur)
    property var apps: [
        { name: "Terminal",     iconName: "kitty",               cmd: ["kitty"],               wmClass: "kitty"   },
        { name: "Firefox",      iconName: "firefox",             cmd: ["firefox"],             wmClass: "firefox" },
//        { name: "Fichiers",     icon: "󰉋",  iconColor: "#C29629", cmd: ["dolphin"],              wmClass: "dolphin"  }
        { name: "Fichiers",     iconName: "org.kde.dolphin", cmd: ["dolphin"],             wmClass: "dolphin" }
    ]

    // Îlot centré, largeur adaptée au nombre d'icônes
    Rectangle {
        id: dockBg
        property int itemSz: theme.dockHeight - 4
        property int cnt:    root.apps.length

        width:  cnt * itemSz + (cnt - 1) * 8 + 24
        height: theme.dockHeight
        radius: theme.dockRadius

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter

        color: theme.bg
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.35)
        border.width: 0 // Epaisseur du contour du dock

        Row {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.apps

                delegate: Item {
                    id: dockItem
                    required property var  modelData
                    required property int  index

                    property bool isOpen: {
                        if (!modelData.wmClass) return false
                        var wins = Hyprland.windows.values
                        for (var i = 0; i < wins.length; i++) {
                            if (wins[i].resourceClass.toLowerCase() ===
                                modelData.wmClass.toLowerCase()) return true
                        }
                        return false
                    }

                    width:  dockBg.itemSz
                    height: dockBg.itemSz

                    // Fond + scale hover
                    Rectangle {
                        id: btnRect
                        anchors.fill: parent
                        radius: theme.dockRadius - 4
                        color:  btnMa.containsMouse ? Qt.rgba(46/255,37/255,37/255,0.9) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        transform: Scale {
                            origin.x: btnRect.width  / 2
                            origin.y: btnRect.height / 2
                            xScale: btnMa.containsMouse ? 1.13 : 1.0
                            yScale: btnMa.containsMouse ? 1.13 : 1.0
                            Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        // Icône système via Quickshell.iconPath()
                        // check:true → string vide si l'icône n'existe pas (pas de texture "manquante")
                        Image {
                            anchors.centerIn:          parent
                            anchors.verticalCenterOffset: -2
                            width:  28
                            height: 28
                            source: Quickshell.iconPath(dockItem.modelData.iconName, true)
                            // Si l'icône est introuvable, on affiche le nom en fallback
                            visible: source !== ""
                            smooth: true
                            mipmap: true
                        }

                        // Fallback texte si aucune icône trouvée
                        Text {
                            anchors.centerIn: parent
                            text:  dockItem.modelData.name.charAt(0)
                            color: theme.fg
                            font.family:    theme.font
                            font.pixelSize: 18
                            font.bold:      true
                            visible: Quickshell.iconPath(dockItem.modelData.iconName, true) === ""
                        }
                    }

                    // Pastille rouge = app ouverte
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom:           parent.bottom
                        anchors.bottomMargin:     2
                        width:  dockItem.isOpen ? 14 : 0
                        height: 3
                        radius: 2
                        color:  "#A32335"
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    // Tooltip
                    Rectangle {
                        visible:  btnMa.containsMouse
                        color:    theme.bgFloat
                        radius:   5
                        height:   tooltipTxt.implicitHeight + 8
                        width:    tooltipTxt.implicitWidth  + 12
                        anchors.bottom:           parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin:     6

                        Text {
                            id: tooltipTxt
                            anchors.centerIn: parent
                            text:  dockItem.modelData.name
                            color: theme.fg
                            font.family:    theme.font
                            font.pixelSize: theme.fontSizeSm
                        }
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    Quickshell.execDetached(dockItem.modelData.cmd)
                    }
                }
            }
        }
    }
}
