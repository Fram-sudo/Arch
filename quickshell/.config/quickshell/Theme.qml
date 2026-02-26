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

    // ── Typographie ───────────────────────────────────────────────────────
    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property int fontSize:    13
    readonly property int fontSizeSm:  11
    readonly property int iconSize:    14

    // ══════════════════════════════════════════════════════════════════════
    // ══ GLASSMORPHISM COMMUN — tokens partagés bar / dock / popups ══════
    // ══════════════════════════════════════════════════════════════════════

    // ── Fond glassmorphism (semi-transparent noir) ────────────────────────
    readonly property color glassBg:           Qt.rgba(10/255, 8/255, 14/255, 0.62)
    readonly property color glassBorder:       Qt.rgba(1, 1, 1, 0.10)
    readonly property int   glassBorderWidth:  1
    readonly property color glossTop:          Qt.rgba(1, 1, 1, 0.07)
    readonly property color glossBottom:       Qt.rgba(1, 1, 1, 0.00)
    readonly property real  glossHeight:       0.45

    // ── Hover sur éléments dans le verre ──────────────────────────────────
    readonly property color glassHover:        Qt.rgba(1, 1, 1, 0.10)
    readonly property color glassHoverBorder:  Qt.rgba(1, 1, 1, 0.14)
    readonly property color glassPressed:      Qt.rgba(1, 1, 1, 0.16)

    // ══════════════════════════════════════════════════════════════════════
    // ══ BARRE (TopBar) ══════════════════════════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    readonly property int barHeight:   32
    readonly property int barRadius:   0
    readonly property int barMarginH:  0
    readonly property int barMarginTop: 0
    readonly property color barBg:     Qt.rgba(8/255, 8/255, 10/255, 0.92)

    // ══════════════════════════════════════════════════════════════════════
    // ══ DOCK ════════════════════════════════════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    readonly property int dockMargin:  2
    readonly property int dockHeight:  50
    readonly property int dockRadius:  14

    // ══════════════════════════════════════════════════════════════════════
    // ══ POPUP — fond opaque avec dégradé teinté rouge ═══════════════════
    // ══════════════════════════════════════════════════════════════════════

    // ── Conteneur principal ───────────────────────────────────────────────
    readonly property color popupBg:            Qt.rgba(8/255, 8/255, 10/255, 0.95)
    readonly property int   popupRadius:        22
    readonly property int   popupPadding:       16
    readonly property color popupBorder:        Qt.rgba(1, 1, 1, 0.06)
    readonly property int   popupBorderWidth:   1

    // ── Dégradé subtil (blanc très léger en haut → transparent) ──────────
    readonly property real  popupGlossHeight:   0.50
    readonly property color popupGlossTop:      Qt.rgba(1, 1, 1, 0.04)
    readonly property color popupGlossBottom:   Qt.rgba(1, 1, 1, 0.00)

    // ── Éléments interactifs ──────────────────────────────────────────────
    readonly property color popupHover:         Qt.rgba(1, 1, 1, 0.08)
    readonly property color popupHoverBorder:   Qt.rgba(1, 1, 1, 0.12)
    readonly property color popupPressed:       Qt.rgba(1, 1, 1, 0.14)

    // ── Accent rouge ──────────────────────────────────────────────────────
    readonly property color popupAccent:        Qt.rgba(163/255, 35/255, 53/255, 0.55)
    readonly property color popupAccentBright:  Qt.rgba(163/255, 35/255, 53/255, 0.75)

    // ── Cadres internes (grilles, sections) ───────────────────────────────
    readonly property color popupInnerBg:       Qt.rgba(1, 1, 1, 0.04)
    readonly property color popupInnerBorder:   Qt.rgba(1, 1, 1, 0.06)
    readonly property int   popupInnerRadius:   14

    // ── Séparateurs ───────────────────────────────────────────────────────
    readonly property color popupSeparator:     Qt.rgba(1, 1, 1, 0.05)

    // ── Texte popup ───────────────────────────────────────────────────────
    readonly property color popupFg:            Qt.rgba(1, 1, 1, 0.92)
    readonly property color popupFgMuted:       Qt.rgba(1, 1, 1, 0.45)
    readonly property color popupFgDim:         Qt.rgba(1, 1, 1, 0.18)

    // ── Sliders QuickSettings ─────────────────────────────────────────────
    readonly property color sliderTrack:        Qt.rgba(1, 1, 1, 0.07)
    readonly property color sliderFill:         "#A32335"
    readonly property color sliderKnob:         "#E2D9E0"
    readonly property int   sliderHeight:       6
    readonly property int   sliderKnobSize:     14
    readonly property int   sliderRadius:       3

    // ── Toggle pills (QS) ─────────────────────────────────────────────────
    readonly property color toggleActiveBg:     Qt.rgba(163/255, 35/255, 53/255, 0.55)
    readonly property color toggleActiveBorder: Qt.rgba(163/255, 35/255, 53/255, 0.70)
    readonly property color toggleInactiveBg:   Qt.rgba(1, 1, 1, 0.05)
    readonly property color toggleInactiveBorder: Qt.rgba(1, 1, 1, 0.07)
    readonly property int   toggleRadius:       14

    // ── Animations ────────────────────────────────────────────────────────
    readonly property int   popupAnimFast:      80
    readonly property int   popupAnimNormal:    150
}
