// Theme.qml — Palette centralisée (Singleton).
// Accessible partout via Theme.bg, Theme.font, etc.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // ── Fond ──────────────────────────────────────────────────────────────
    readonly property color bg:        "#1D171E"
    readonly property color bgFloat:   "#231C1E"
    readonly property color bgHover:   "#2E2525"

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
    readonly property int dockMargin:  2
    readonly property int dockHeight:  50
    readonly property int dockRadius:  14

    // ── Typographie ───────────────────────────────────────────────────────
    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property int fontSize:    13
    readonly property int fontSizeSm:  11
    readonly property int iconSize:    14

    // ══════════════════════════════════════════════════════════════════════
    // ══ POPUP GLASSMORPHISM — noir semi-transparent, accent rouge ════════
    // ══════════════════════════════════════════════════════════════════════

    // ── Conteneur principal ───────────────────────────────────────────────
    readonly property color popupBg:            Qt.rgba(10/255, 8/255, 14/255, 0.72)
    readonly property int   popupRadius:        18
    readonly property int   popupPadding:       14
    readonly property color popupBorder:        Qt.rgba(1, 1, 1, 0.08)
    readonly property int   popupBorderWidth:   1

    // ── Reflet glossy (dégradé blanc en haut) ─────────────────────────────
    readonly property real  popupGlossHeight:   0.42
    readonly property color popupGlossTop:      Qt.rgba(1, 1, 1, 0.06)
    readonly property color popupGlossBottom:   Qt.rgba(1, 1, 1, 0.00)

    // ── Éléments interactifs ──────────────────────────────────────────────
    readonly property color popupHover:         Qt.rgba(1, 1, 1, 0.10)
    readonly property color popupHoverBorder:   Qt.rgba(1, 1, 1, 0.14)
    readonly property color popupPressed:       Qt.rgba(1, 1, 1, 0.16)

    // ── Accent rouge (plus doux que le red global) ────────────────────────
    readonly property color popupAccent:        Qt.rgba(163/255, 35/255, 53/255, 0.55)
    readonly property color popupAccentBright:  Qt.rgba(163/255, 35/255, 53/255, 0.75)

    // ── Cadres internes (grilles, sections) ───────────────────────────────
    readonly property color popupInnerBg:       Qt.rgba(1, 1, 1, 0.05)
    readonly property color popupInnerBorder:   Qt.rgba(1, 1, 1, 0.08)
    readonly property int   popupInnerRadius:   12

    // ── Séparateurs ───────────────────────────────────────────────────────
    readonly property color popupSeparator:     Qt.rgba(1, 1, 1, 0.06)

    // ── Texte popup ───────────────────────────────────────────────────────
    readonly property color popupFg:            Qt.rgba(1, 1, 1, 0.90)
    readonly property color popupFgMuted:       Qt.rgba(1, 1, 1, 0.42)
    readonly property color popupFgDim:         Qt.rgba(1, 1, 1, 0.18)

    // ── Animations ────────────────────────────────────────────────────────
    readonly property int   popupAnimFast:      80
    readonly property int   popupAnimNormal:    150
}
