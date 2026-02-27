// CalendarPopup.qml — Popup calendrier style macOS Tahoe
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: win
    property bool open:         false
    property int  clockCenterX: 0

    signal closeRequested()

    // Plein écran pour capturer les clics hors popup
    anchors.top:    true
    anchors.left:   true
    anchors.right:  true
    anchors.bottom: true

    // Décalage du contenu visuel
    property int panelLeft: Math.max(8, clockCenterX - panelWidth / 2)
    property int panelTop:  Theme.barHeight + 6
    property int panelWidth: 320

    // MouseArea plein écran — ferme si clic hors du rectangle visuel
    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            var inPanel = (mouse.x >= win.panelLeft &&
                           mouse.x <= win.panelLeft + win.panelWidth &&
                           mouse.y >= win.panelTop &&
                           mouse.y <= win.panelTop + calPanel.height)
            if (!inPanel) win.closeRequested()
        }
        // Laisser passer les clics vers le contenu
        propagateComposedEvents: true
    }

    // ── Calendrier ────────────────────────────────────────────────────────
    property int todayDay:    1
    property int todayMonth:  1
    property int todayYear:   2025
    property int viewMonth:   todayMonth
    property int viewYear:    todayYear
    property int selectedDay: -1
    property int selectedMonth: -1
    property int selectedYear:  -1
    property bool showYearPicker: false

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dayNames: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    property int firstDay:   (new Date(viewYear, viewMonth-1, 1).getDay() + 6) % 7
    property int dimCurrent: new Date(viewYear, viewMonth, 0).getDate()
    property int dimPrev:    new Date(viewMonth === 1 ? viewYear-1 : viewYear,
                                      viewMonth === 1 ? 11 : viewMonth-1, 0).getDate()
    property int gridRows:   Math.ceil((firstDay + dimCurrent) / 7)
    property int cellH:      36
    property int cellW:      Math.floor(292 / 7)

    property int contentHeight: showYearPicker
        ? (14 + 44 + 10 + 6 + 160 + 14)
        : (14 + 44 + 10 + 6 + 22 + 4 + (gridRows * cellH) + 16 + 16 + 14)
        // 16 = padding interne Rectangle (8 top + 8 bottom), dernier 16 = marge basse colonne

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || slideAnim.running

    function prevMonth() {
        if (viewMonth === 1) { viewMonth = 12; viewYear-- } else viewMonth--
        showYearPicker = false
    }
    function nextMonth() {
        if (viewMonth === 12) { viewMonth = 1; viewYear++ } else viewMonth++
        showYearPicker = false
    }

    Process {
        command: ["date", "+%d %m %Y"]; running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split(" ")
                win.todayDay   = parseInt(p[0])
                win.todayMonth = parseInt(p[1])
                win.todayYear  = parseInt(p[2])
                win.viewMonth  = win.todayMonth
                win.viewYear   = win.todayYear
            }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: calPanel
            x: win.panelLeft
            width:  win.panelWidth
            height: win.contentHeight
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            // Animation slide depuis sous la barre
            y: win.open ? win.panelTop : win.panelTop - height - 10
            Behavior on y {
                NumberAnimation {
                    id: slideAnim
                    duration: 320
                    easing.type: win.open ? Easing.OutQuart : Easing.InQuart
                }
            }

            // Opacité liée au slide
            opacity: win.open ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

            layer.enabled: !Theme.isDark
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset:  Theme.popupShadowX
                verticalOffset:    Theme.popupShadowY
                radius:            Theme.popupShadowRadius
                samples:           32
                color:             Qt.rgba(0, 0, 0, Theme.popupShadowOpacity)
            }

            // Glossy
            Rectangle {
                z: 0
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: parent.height * Theme.popupGlossHeight; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.popupGlossTop }
                    GradientStop { position: 1.0; color: Theme.popupGlossBottom }
                }
            }

            Column {
                z: 1
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // ── En-tête mois / année ──────────────────────────────────
                Item {
                    width: parent.width; height: 44

                    // Bouton précédent
                    Rectangle {
                        id: prevBtn
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; radius: 8
                        color: prevMa.containsMouse ? Theme.glassPressed : Theme.glassHover
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent; text: "‹"
                            color: Theme.popupFg; font.family: Theme.font
                            font.pixelSize: 16; font.weight: Font.Medium
                        }
                        MouseArea {
                            id: prevMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: win.prevMonth()
                        }
                    }

                    // Mois + Année (cliquable → year picker)
                    Rectangle {
                        anchors.centerIn: parent
                        width: monthLabel.implicitWidth + 20; height: 28; radius: 8
                        color: headerMa.containsMouse ? Theme.glassHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            id: monthLabel
                            anchors.centerIn: parent
                            text: win.monthNames[win.viewMonth - 1] + " " + win.viewYear
                            color: Theme.popupFg
                            font.family: Theme.font; font.pixelSize: 15
                            font.weight: Font.SemiBold
                        }
                        MouseArea {
                            id: headerMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: win.showYearPicker = !win.showYearPicker
                        }
                    }

                    // Bouton suivant
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; radius: 8
                        color: nextMa.containsMouse ? Theme.glassPressed : Theme.glassHover
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent; text: "›"
                            color: Theme.popupFg; font.family: Theme.font
                            font.pixelSize: 16; font.weight: Font.Medium
                        }
                        MouseArea {
                            id: nextMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: win.nextMonth()
                        }
                    }
                }

                // Séparateur
                Rectangle {
                    width: parent.width; height: 1
                    color: Theme.separator
                }

                // ── Year Picker ────────────────────────────────────────────
                GridView {
                    visible: win.showYearPicker
                    width: parent.width; height: 160
                    clip: true
                    cellWidth: parent.width / 4; cellHeight: 40
                    model: 24
                    property int startYear: win.todayYear - 6

                    delegate: Item {
                        required property int index
                        property int yr: GridView.view.startYear + index
                        width: GridView.view.cellWidth; height: GridView.view.cellHeight

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 3; radius: 8
                            color: yr === win.viewYear ? Theme.red
                                 : yrMa.containsMouse  ? Theme.glassHover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Text {
                                anchors.centerIn: parent; text: parent.parent.yr
                                color: yr === win.viewYear ? "#fff"
                                     : Qt.rgba(Theme.popupFg.r, Theme.popupFg.g, Theme.popupFg.b, yr === win.todayYear ? 0.9 : 0.5)
                                font.family: Theme.font; font.pixelSize: 12
                                font.weight: yr === win.todayYear ? Font.SemiBold : Font.Normal
                            }
                            MouseArea {
                                id: yrMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { win.viewYear = parent.parent.yr; win.showYearPicker = false }
                            }
                        }
                    }
                }

                // ── Grille calendrier ──────────────────────────────────────
                Rectangle {
                    visible: !win.showYearPicker
                    width: parent.width
                    height: calGrid.implicitHeight + 16
                    radius: 12
                    color: Theme.innerBg
                    border.color: Theme.innerBorder
                    border.width: 1

                    Column {
                        id: calGrid
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 0

                    // Noms des jours
                    Row {
                        width: parent.width
                        Repeater {
                            model: win.dayNames
                            Text {
                                required property string modelData
                                width: win.cellW; height: 22
                                text: modelData
                                color: Theme.popupFgMuted
                                font.family: Theme.font; font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // Séparateur
                    Rectangle {
                        width: parent.width; height: 1; color: Theme.separator
                    }
                    Item { width: 1; height: 4 }

                    // Cellules
                    Item {
                        width: parent.width
                        height: win.gridRows * win.cellH

                        // Jours du mois précédent
                        Repeater {
                            model: win.firstDay
                            delegate: Item {
                                required property int index
                                x: index * win.cellW; y: 0
                                width: win.cellW; height: win.cellH
                                Text {
                                    anchors.centerIn: parent
                                    text: win.dimPrev - win.firstDay + 1 + index
                                    color: Theme.popupFgDim
                                    font.family: Theme.font; font.pixelSize: 13
                                }
                            }
                        }

                        // Jours du mois courant
                        Repeater {
                            model: win.dimCurrent
                            delegate: Item {
                                required property int index
                                property int offset: win.firstDay + index
                                property int col:    offset % 7
                                property int row:    Math.floor(offset / 7)
                                property int day:    index + 1
                                property bool isToday: day === win.todayDay && win.viewMonth === win.todayMonth && win.viewYear === win.todayYear
                                property bool isSelected: day === win.selectedDay && win.viewMonth === win.selectedMonth && win.viewYear === win.selectedYear
                                property bool isWeekend: col >= 5

                                x: col * win.cellW; y: row * win.cellH
                                width: win.cellW; height: win.cellH

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 30; height: 30; radius: 8
                                    color: isSelected ? Theme.glassPressed
                                         : isToday    ? Theme.red
                                         : dayMa.containsMouse ? Theme.glassHover
                                         : "transparent"
                                    border.color: isSelected ? Theme.border : "transparent"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent; text: parent.parent.day
                                        color: (isToday || isSelected) ? "#fff"
                                             : isWeekend ? Theme.popupFgMuted : Theme.popupFg
                                        font.family: Theme.font; font.pixelSize: 13
                                        font.weight: isToday ? Font.SemiBold : Font.Normal
                                    }
                                }
                                MouseArea {
                                    id: dayMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.selectedDay   = day
                                        win.selectedMonth = win.viewMonth
                                        win.selectedYear  = win.viewYear
                                    }
                                }
                            }
                        }
                    }
                    } // fin Column calGrid
                } // fin Rectangle cadre calendrier
            }
        }
    }
}