// shell.qml — Point d'entrée Quickshell
import QtQuick
import Quickshell
import qs.bar
import qs.dock
import qs.dashboard

ShellRoot {
    // ── Dashboard (instance unique, non lié à un écran) ───────────────────
    Dashboard { id: dashboard }

    // ── Bar + Dock par écran ──────────────────────────────────────────────
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
