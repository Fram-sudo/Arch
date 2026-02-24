// CalendarPopup.qml
import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: win
    property bool open:        false
    property int  clockCenterX: 0

    anchors.top:  true
    anchors.left: true
    margins.top:  theme.barHeight + 4
    margins.left: Math.max(4, clockCenterX - implicitWidth / 2)

    implicitWidth:  300
    implicitHeight: yearPicker.visible ? 260 : 286

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

    Theme { id: theme }

    // ── Date aujourd'hui ──────────────────────────────────────────────────
    property int todayDay:   1
    property int todayMonth: 1
    property int todayYear:  2025

    // ── Navigation ────────────────────────────────────────────────────────
    property int viewMonth: todayMonth
    property int viewYear:  todayYear

    // ── Sélection ─────────────────────────────────────────────────────────
    property int selectedDay:   todayDay
    property int selectedMonth: todayMonth
    property int selectedYear:  todayYear

    // ── Mode vue ──────────────────────────────────────────────────────────
    property bool showYearPicker: false

    Process {
        command: ["date", "+%d %m %Y"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split(" ")
                win.todayDay   = parseInt(p[0])
                win.todayMonth = parseInt(p[1])
                win.todayYear  = parseInt(p[2])
                win.viewMonth  = win.todayMonth
                win.viewYear   = win.todayYear
                win.selectedDay   = win.todayDay
                win.selectedMonth = win.todayMonth
                win.selectedYear  = win.todayYear
            }
        }
    }

    readonly property var monthNames: [
        "Janvier","Février","Mars","Avril","Mai","Juin",
        "Juillet","Août","Septembre","Octobre","Novembre","Décembre"
    ]
    readonly property var dayNames: ["L","M","M","J","V","S","D"]

    function firstDayOfMonth(y, m) { return (new Date(y, m-1, 1).getDay() + 6) % 7 }
    function daysInMonth(y, m)     { return new Date(y, m, 0).getDate() }

    function prevMonth() {
        if (viewMonth === 1) { viewMonth = 12; viewYear-- }
        else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 12) { viewMonth = 1; viewYear++ }
        else viewMonth++
    }

    // ── Fond principal ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       theme.popupRadius
        color:        theme.bgPopup
        border.color: Qt.rgba(163/255, 35/255, 53/255, 0.4)
        border.width: 1
        opacity:      win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        clip: true

        Column {
            anchors.fill:    parent
            anchors.margins: 12
            spacing:         8

            // ── En-tête ───────────────────────────────────────────────────
            Item {
                width:  parent.width
                height: 28

                // Flèche gauche
                Text {
                    anchors.left:           parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹"; color: prevMa.containsMouse ? theme.fg : theme.fgMuted
                    font.pixelSize: 20; font.family: theme.font
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: prevMa; anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.prevMonth()
                    }
                }

                // Mois + année cliquables → ouvre sélecteur année
                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: win.monthNames[win.viewMonth - 1]
                        color: theme.fg
                        font.family: theme.font; font.pixelSize: theme.fontSizeSm; font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        height: 20; width: yearTxt.implicitWidth + 10; radius: 4
                        color: yearMa.containsMouse ? theme.bgHover : Qt.rgba(46/255,37/255,37/255,0.6)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: yearTxt
                            anchors.centerIn: parent
                            text: win.viewYear
                            color: win.showYearPicker ? theme.red : theme.fg
                            font.family: theme.font; font.pixelSize: theme.fontSizeSm; font.bold: true
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        MouseArea {
                            id: yearMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: win.showYearPicker = !win.showYearPicker
                        }
                    }
                }

                // Flèche droite
                Text {
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"; color: nextMa.containsMouse ? theme.fg : theme.fgMuted
                    font.pixelSize: 20; font.family: theme.font
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: nextMa; anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.nextMonth()
                    }
                }
            }

            // ── Sélecteur d'année ─────────────────────────────────────────
            Item {
                id: yearPicker
                width:  parent.width
                height: visible ? 160 : 0
                visible: win.showYearPicker
                clip: true

                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                GridView {
                    id: yearGrid
                    anchors.fill: parent
                    cellWidth:  parent.width / 4
                    cellHeight: 36
                    clip: true

                    // Affiche 20 ans autour de l'année courante
                    model: 24
                    property int startYear: win.todayYear - 4

                    delegate: Item {
                        required property int index
                        property int yr: yearGrid.startYear + index
                        width: yearGrid.cellWidth; height: yearGrid.cellHeight

                        Rectangle {
                            anchors.fill:    parent
                            anchors.margins: 2
                            radius: 6
                            color: {
                                if (yr === win.viewYear)   return theme.red
                                if (yrMa.containsMouse)    return theme.bgHover
                                return "transparent"
                            }
                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.centerIn: parent
                                text:  parent.parent.yr
                                color: yr === win.viewYear ? "#fff" : theme.fg
                                font.family:    theme.font
                                font.pixelSize: theme.fontSizeSm - 1
                                font.bold:      yr === win.todayYear
                            }

                            MouseArea {
                                id: yrMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.viewYear = parent.parent.yr
                                    win.showYearPicker = false
                                }
                            }
                        }
                    }

                    Component.onCompleted: {
                        // Scroll pour centrer l'année courante
                        var idx = win.viewYear - yearGrid.startYear
                        positionViewAtIndex(Math.max(0, idx - 4), GridView.Beginning)
                    }
                }
            }

            // ── Grille calendrier ─────────────────────────────────────────
            Column {
                visible: !win.showYearPicker
                width:   parent.width
                spacing: 4

                // Jours de la semaine
                Row {
                    width: parent.width
                    Repeater {
                        model: win.dayNames
                        Text {
                            required property string modelData
                            width:  (win.implicitWidth - 24) / 7
                            text:   modelData
                            color:  theme.fgDim
                            font.pixelSize: 10; font.family: theme.font
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Cases du mois
                Grid {
                    columns: 7
                    spacing: 2
                    width:   parent.width

                    // Cases vides avant le 1er
                    Repeater {
                        model: win.firstDayOfMonth(win.viewYear, win.viewMonth)
                        Item { width: (win.implicitWidth - 24) / 7; height: 26 }
                    }

                    // Jours
                    Repeater {
                        model: win.daysInMonth(win.viewYear, win.viewMonth)
                        delegate: Rectangle {
                            required property int index
                            property int  day:        index + 1
                            property bool isToday:    day === win.todayDay    && win.viewMonth === win.todayMonth && win.viewYear === win.todayYear
                            property bool isSelected: day === win.selectedDay && win.viewMonth === win.selectedMonth && win.viewYear === win.selectedYear
                            property bool isWeekend:  (win.firstDayOfMonth(win.viewYear, win.viewMonth) + index) % 7 >= 5

                            width:  (win.implicitWidth - 24) / 7
                            height: 26
                            radius: 6

                            color: isSelected ? theme.red
                                 : isToday    ? Qt.rgba(163/255, 35/255, 53/255, 0.25)
                                 : dayMa.containsMouse ? theme.bgHover
                                 : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            // Petit point sous le jour d'aujourd'hui si pas sélectionné
                            Rectangle {
                                visible: isToday && !isSelected
                                anchors.bottom:           parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin:     1
                                width: 3; height: 3; radius: 2
                                color: theme.red
                            }

                            Text {
                                anchors.centerIn: parent
                                text:  parent.day
                                color: isSelected ? "#fff"
                                     : isToday    ? theme.red
                                     : isWeekend  ? theme.fgMuted
                                     :              theme.fg
                                font.pixelSize: theme.fontSizeSm - 1
                                font.family:    theme.font
                                font.bold:      isToday || isSelected
                            }

                            MouseArea {
                                id: dayMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.selectedDay   = parent.day
                                    win.selectedMonth = win.viewMonth
                                    win.selectedYear  = win.viewYear
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
