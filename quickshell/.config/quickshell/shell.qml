// shell.qml — Point d'entrée Quickshell
// Tous les fichiers sont dans le même dossier → pas de modules à déclarer.
// Quickshell détecte automatiquement TopBar.qml, Dock.qml et Theme.qml.
import QtQuick
import Quickshell

ShellRoot {
    // Instancie la barre et le dock sur chaque écran
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                required property var modelData

                TopBar { screen: modelData }
                Dock   { screen: modelData }
            }
        }
    }
}
