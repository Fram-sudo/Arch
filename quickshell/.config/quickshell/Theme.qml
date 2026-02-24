// Theme.qml — Palette centralisée. Modifiez ici pour changer tout le shell.
import QtQuick

QtObject {
    // ── Fond ──────────────────────────────────────────────────────────────
    readonly property color bg:        "#1D171E"
    readonly property color bgFloat:   "#231C1E"
    readonly property color bgHover:   "#2E2525"
    readonly property color bgPopup:   "#1A1418"

    // ── Texte ─────────────────────────────────────────────────────────────
    readonly property color fg:        "#E2D9E0"
    readonly property color fgMuted:   "#8A7A88"
    readonly property color fgDim:     "#4A3A48"

    // ── Accent rouge sang ─────────────────────────────────────────────────
    readonly property color red:       "#A32335"
    readonly property color redBright: "#C2293F"

    // ── Harmoniques ───────────────────────────────────────────────────────
    readonly property color teal:      "#5A9494"
    readonly property color gold:      "#C29629"

    // ── Géométrie barre ───────────────────────────────────────────────────
    readonly property int barHeight:   32
    readonly property int barRadius:   0
    readonly property int popupRadius: 10
    readonly property int dockMargin:  2
    readonly property int dockHeight:  50
    readonly property int dockRadius:  14

    // ── Typographie ───────────────────────────────────────────────────────
    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property int fontSize:    13
    readonly property int fontSizeSm:  11
    readonly property int iconSize:    14
}
