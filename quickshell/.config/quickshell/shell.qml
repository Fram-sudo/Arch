import QtQuick
import QtQuick.Layouts
import Quickshell
// On importe le module qui permet à Quickshell de parler avec Hyprland
import Quickshell.Hyprland

ShellRoot {
    // 1. On crée une horloge invisible qui se met à jour chaque minute
    SystemClock {
        id: time
        precision: SystemClock.Minutes
    }

    PanelWindow {
        id: topBar
        
        anchors {
            top: true
            left: true
            right: true
        }
        
        height: 35
        color: "#1D171E" // Ton fond noir

        // Un conteneur qui garde 15 pixels de marge de chaque côté de l'écran
        Item {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15

           // ==========================================
            // GAUCHE : ESPACES DE TRAVAIL & FENÊTRE ACTIVE
            // ==========================================
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 15 // Espace entre les espaces de travail et le titre de la fenêtre

                // --- 1. Les carrés des espaces de travail ---
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            property int wsId: index + 1
                            property bool isActive: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === wsId) : false

                            width: 22
                            height: 21
                            radius: 2
                            color: isActive ? "#A32335" : "#2E2525"
                            
                            Text {
                                anchors.centerIn: parent
                                text: wsId
                                color: isActive ? "#1D171E" : "#E2D9E0"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }
                }

                // --- 2. Un petit séparateur vertical bordeaux ---
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 16
                    radius: 1
                    color: "#A32335"
                }

                // --- 3. Le titre de la fenêtre active ---
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    // CORRECTION : On utilise activeWindow !
                    text: Hyprland.activeWindow ? Hyprland.activeWindow.title : "Bureau"
                    color: "#E2D9E0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    width: 300 
                }                                                                             
                
            } 

            // ==========================================
            // CENTRE : HORLOGE ET DATE
            // ==========================================
            Text {
                anchors.centerIn: parent
                // On utilise la date récupérée en haut, et on choisit son format
                text: Qt.formatDateTime(time.date, "hh:mm  |  dddd dd MMMM")
                color: "#E2D9E0" // Ton blanc grisé
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
            }

            // ==========================================
            // DROITE : BOUTON D'EXTINCTION
            // ==========================================
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 6
                color: "#2E2525" // Fond légèrement plus clair que la barre
                
                Text {
                    anchors.centerIn: parent
                    text: "" // Icône d'extinction (Nerd Font)
                    color: "#A32335" // Rouge bordeaux
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                // Cette zone invisible par-dessus le bouton capte les clics
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor // Met la souris en forme de petite main au survol
                    onClicked: {
                        // On ordonne à Hyprland de quitter la session !
                        Hyprland.dispatch("exit")
                    }
                }
            }
        }
    }
}
