// Theme.qml — Palette centralisée (Singleton).
// Accessible partout via Theme.bg, Theme.font, etc.
// Supporte 2 thèmes : dark (par défaut) et light — toggle via Theme.toggleTheme()
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // ══════════════════════════════════════════════════════════════════════
    // ══ TOGGLE THÈME ═════════════════════════════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    property bool isDark: true
    function toggleTheme() { isDark = !isDark }

    // ══════════════════════════════════════════════════════════════════════
    // ══ PALETTE SOMBRE ════════════════════════════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    readonly property color _dark_bg:            "#111010"
    readonly property color _dark_bgFloat:       "#1A1919"
    readonly property color _dark_bgHover:       "#242222"
    readonly property color _dark_fg:            "#F2EFEf"
    readonly property color _dark_fgMuted:       "#888280"
    readonly property color _dark_fgDim:         "#3D3B3B"
    readonly property color _dark_separator:     Qt.rgba(1, 1, 1, 0.06)
    readonly property color _dark_border:        Qt.rgba(1, 1, 1, 0.10)
    // Barre : noir opaque pur
    readonly property color _dark_barBg:         "#000000"
    readonly property color _dark_barFg:         "#FFFFFF"
    readonly property color _dark_barHover:      Qt.rgba(1, 1, 1, 0.08)
    readonly property color _dark_barHoverBorder:Qt.rgba(1, 1, 1, 0.30)
    readonly property color _dark_barSeparator:  Qt.rgba(1, 1, 1, 0.18)
    readonly property color _dark_barWs:         "#FFFFFF"
    readonly property color _dark_barWsBusy:     Qt.rgba(1, 1, 1, 0.45)
    readonly property color _dark_barWsEmpty:    Qt.rgba(1, 1, 1, 0.18)
    // Popups & dock
    readonly property color _dark_popupBg:       Qt.rgba(18/255, 17/255, 17/255, 0.96)
    readonly property color _dark_glassHover:    Qt.rgba(1, 1, 1, 0.08)
    readonly property color _dark_glassPressed:  Qt.rgba(1, 1, 1, 0.13)
    readonly property color _dark_dockBg:        Qt.rgba(10/255, 9/255, 9/255, 0.72)
    readonly property color _dark_innerBg:       Qt.rgba(1, 1, 1, 0.04)
    readonly property color _dark_innerBorder:   Qt.rgba(1, 1, 1, 0.07)
    readonly property color _dark_sliderTrack:   Qt.rgba(1, 1, 1, 0.10)
    readonly property color _dark_toggleInactive:     Qt.rgba(1, 1, 1, 0.06)
    readonly property color _dark_toggleInactiveBorder: Qt.rgba(1, 1, 1, 0.09)
    readonly property color _dark_popupFg:       Qt.rgba(1, 1, 1, 0.93)
    readonly property color _dark_popupFgMuted:  Qt.rgba(1, 1, 1, 0.45)
    readonly property color _dark_popupFgDim:    Qt.rgba(1, 1, 1, 0.18)
    readonly property color _dark_glossTop:      Qt.rgba(1, 1, 1, 0.05)

    // ══════════════════════════════════════════════════════════════════════
    // ══ PALETTE CLAIRE ════════════════════════════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    readonly property color _light_bg:            "#F0EDEC"
    readonly property color _light_bgFloat:       "#E8E4E3"
    readonly property color _light_bgHover:       "#DDD9D8"
    readonly property color _light_fg:            "#1A1818"
    readonly property color _light_fgMuted:       "#7A7674"
    readonly property color _light_fgDim:         "#C5C0BF"
    readonly property color _light_separator:     Qt.rgba(0, 0, 0, 0.07)
    readonly property color _light_border:        Qt.rgba(0, 0, 0, 0.10)
    // Barre : gris chaud semi-transparent
    readonly property color _light_barBg:         Qt.rgba(210/255, 206/255, 204/255, 0.82)
    readonly property color _light_barFg:         "#1A1818"
    readonly property color _light_barHover:      Qt.rgba(0, 0, 0, 0.07)
    readonly property color _light_barHoverBorder:Qt.rgba(0, 0, 0, 0.22)
    readonly property color _light_barSeparator:  Qt.rgba(0, 0, 0, 0.20)
    readonly property color _light_barWs:         "#1A1818"
    readonly property color _light_barWsBusy:     Qt.rgba(0, 0, 0, 0.40)
    readonly property color _light_barWsEmpty:    Qt.rgba(0, 0, 0, 0.18)
    // Popups & dock
    readonly property color _light_popupBg:       Qt.rgba(244/255, 241/255, 240/255, 0.97)
    readonly property color _light_glassHover:    Qt.rgba(0, 0, 0, 0.06)
    readonly property color _light_glassPressed:  Qt.rgba(0, 0, 0, 0.10)
    readonly property color _light_dockBg:        Qt.rgba(215/255, 211/255, 209/255, 0.82)
    readonly property color _light_innerBg:       Qt.rgba(0, 0, 0, 0.03)
    readonly property color _light_innerBorder:   Qt.rgba(0, 0, 0, 0.07)
    readonly property color _light_sliderTrack:   Qt.rgba(0, 0, 0, 0.10)
    readonly property color _light_toggleInactive:     Qt.rgba(0, 0, 0, 0.06)
    readonly property color _light_toggleInactiveBorder: Qt.rgba(0, 0, 0, 0.09)
    readonly property color _light_popupFg:       Qt.rgba(0, 0, 0, 0.88)
    readonly property color _light_popupFgMuted:  Qt.rgba(0, 0, 0, 0.45)
    readonly property color _light_popupFgDim:    Qt.rgba(0, 0, 0, 0.20)
    readonly property color _light_glossTop:      Qt.rgba(1, 1, 1, 0.60)

    // ══════════════════════════════════════════════════════════════════════
    // ══ ACCENT ROUGE (commun aux 2 thèmes) ═══════════════════════════════
    // ══════════════════════════════════════════════════════════════════════
    readonly property color red:            "#C0293D"
    readonly property color redBright:      "#D93348"
    readonly property color redDim:         Qt.rgba(192/255, 41/255, 61/255, 0.55)
    readonly property color redDimBright:   Qt.rgba(192/255, 41/255, 61/255, 0.75)

    // Harmoniques
    readonly property color teal:           "#3A8A8A"
    readonly property color gold:           "#B8891A"

    // ══════════════════════════════════════════════════════════════════════
    // ══ PROPRIÉTÉS DYNAMIQUES (switchent avec isDark) ════════════════════
    // ══════════════════════════════════════════════════════════════════════

    readonly property color bg:           isDark ? _dark_bg           : _light_bg
    readonly property color bgFloat:      isDark ? _dark_bgFloat      : _light_bgFloat
    readonly property color bgHover:      isDark ? _dark_bgHover      : _light_bgHover
    readonly property color fg:           isDark ? _dark_fg           : _light_fg
    readonly property color fgMuted:      isDark ? _dark_fgMuted      : _light_fgMuted
    readonly property color fgDim:        isDark ? _dark_fgDim        : _light_fgDim
    readonly property color separator:    isDark ? _dark_separator    : _light_separator
    readonly property color border:       isDark ? _dark_border       : _light_border

    // ── Barre (propriétés dédiées) ────────────────────────────────────────
    readonly property color barBg:          isDark ? _dark_barBg          : _light_barBg
    readonly property color barFg:          isDark ? _dark_barFg          : _light_barFg
    readonly property color barHover:       isDark ? _dark_barHover       : _light_barHover
    readonly property color barHoverBorder: isDark ? _dark_barHoverBorder : _light_barHoverBorder
    readonly property color barSeparator:   isDark ? _dark_barSeparator   : _light_barSeparator
    readonly property color barWs:          isDark ? _dark_barWs          : _light_barWs
    readonly property color barWsBusy:      isDark ? _dark_barWsBusy      : _light_barWsBusy
    readonly property color barWsEmpty:     isDark ? _dark_barWsEmpty     : _light_barWsEmpty

    // ── Popups & dock ─────────────────────────────────────────────────────
    readonly property color popupBg:      isDark ? _dark_popupBg      : _light_popupBg
    readonly property color glassHover:   isDark ? _dark_glassHover   : _light_glassHover
    readonly property color glassPressed: isDark ? _dark_glassPressed : _light_glassPressed
    readonly property color dockBg:       isDark ? _dark_dockBg       : _light_dockBg
    readonly property color innerBg:      isDark ? _dark_innerBg      : _light_innerBg
    readonly property color innerBorder:  isDark ? _dark_innerBorder  : _light_innerBorder
    readonly property color sliderTrack:  isDark ? _dark_sliderTrack  : _light_sliderTrack
    readonly property color toggleInactive:       isDark ? _dark_toggleInactive       : _light_toggleInactive
    readonly property color toggleInactiveBorder: isDark ? _dark_toggleInactiveBorder : _light_toggleInactiveBorder
    readonly property color popupFg:      isDark ? _dark_popupFg      : _light_popupFg
    readonly property color popupFgMuted: isDark ? _dark_popupFgMuted : _light_popupFgMuted
    readonly property color popupFgDim:   isDark ? _dark_popupFgDim   : _light_popupFgDim
    readonly property color glossTop:     isDark ? _dark_glossTop     : _light_glossTop

    // ── Aliases pratiques ─────────────────────────────────────────────────
    readonly property color popupAccent:      redDim
    readonly property color popupAccentBright:redDimBright
    readonly property color popupHover:       glassHover
    readonly property color popupHoverBorder: border
    readonly property color popupPressed:     glassPressed
    readonly property color popupBorder:      border
    readonly property color popupSeparator:   separator
    readonly property color popupInnerBg:     innerBg
    readonly property color popupInnerBorder: innerBorder
    readonly property color sliderFill:       red
    readonly property color sliderKnob:       isDark ? "#F2EFEF" : "#FFFFFF"
    readonly property color toggleActiveBg:      redDim
    readonly property color toggleActiveBorder:  redDimBright

    // ── Typographie ───────────────────────────────────────────────────────
    readonly property string font:      "Inter"
    readonly property string fontMono:  "JetBrainsMono Nerd Font"
    readonly property int fontSize:     13
    readonly property int fontSizeSm:   11
    readonly property int fontSizeXs:   10
    readonly property int iconSize:     14

    // ── Barre ─────────────────────────────────────────────────────────────
    readonly property int barHeight:    28
    readonly property int barRadius:    0

    // ── Dock ──────────────────────────────────────────────────────────────
    readonly property int dockHeight:   64
    readonly property int dockIconSize: 52
    readonly property int dockPadding:  8
    readonly property int dockRadius:   18
    readonly property int dockMargin:   8

    // ── Glassmorphism (dock + popups) ─────────────────────────────────────
    readonly property color glassBg:          dockBg
    readonly property color glassBorder:      border
    readonly property int   glassBorderWidth: 1
    readonly property real  glossHeight:      0.45
    readonly property color glossBottom:      Qt.rgba(1,1,1,0.00)

    // ── Popup ─────────────────────────────────────────────────────────────
    readonly property int   popupRadius:      18
    readonly property int   popupPadding:     14
    readonly property int   popupBorderWidth: 1
    readonly property real  popupGlossHeight: glossHeight
    readonly property color popupGlossTop:    glossTop
    readonly property color popupGlossBottom: glossBottom

    // ── Sliders ───────────────────────────────────────────────────────────
    readonly property int sliderHeight:   5
    readonly property int sliderKnobSize: 13
    readonly property int sliderRadius:   3
    readonly property int toggleRadius:   12

    // ── Animations ────────────────────────────────────────────────────────
    readonly property int animFast:   80
    readonly property int animNormal: 200
    readonly property int animSlow:   350

}
