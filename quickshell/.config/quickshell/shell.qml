// shell.qml — Point d'entrée Quickshell
import QtQuick
import Quickshell
import qs.bar
import qs.dock

ShellRoot {
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
