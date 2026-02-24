// Theme.qml — Palette centralisée
// Utilisé comme objet instancié dans chaque composant : Theme { id: theme }
import QtQuick

QtObject {
    // ── Fond ──────────────────────────────────────────────────────────────
    readonly property color bg:        "#1D171E"
    readonly property color bgFloat:   "#231C1E"
    readonly property color bgHover:   "#2E2525"

    // ── Texte ─────────────────────────────────────────────────────────────
    readonly property color fg:        "#E2D9E0"
    readonly property color fgMuted:   "#8A7A88"

    // ── Accent rouge sang ─────────────────────────────────────────────────
    readonly property color red:       "#A32335"
    readonly property color redBright: "#C2293F"

    // ── Harmoniques sobres ────────────────────────────────────────────────
    readonly property color teal:      "#5A9494"
    readonly property color gold:      "#C29629"

    // ── Géométrie ─────────────────────────────────────────────────────────
    readonly property int barHeight:   36
    readonly property int barRadius:   10
    readonly property int barMargin:   2 // Pour monter/descendre la barre
    readonly property int dockMargin:  2 // dock du bas ↔ bord écran
    readonly property int dockHeight:  50
    readonly property int dockRadius:  14

    // ── Typographie ───────────────────────────────────────────────────────
    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property int fontSize:    13
    readonly property int fontSizeSm:  11
    readonly property int iconSize:    16
}
