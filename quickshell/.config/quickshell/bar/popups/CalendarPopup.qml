// CalendarPopup.qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs

PanelWindow {
    id: win
    property bool open:         false
    property int  clockCenterX: 0

    anchors.top:  true
    anchors.left: true
    margins.top:  Theme.barHeight
    margins.left: Math.max(4, clockCenterX - implicitWidth / 2)

    implicitWidth:  340

    property int cellH:      38
    property int cellW:      Math.floor(300 / 7)
    property int firstDay:   (new Date(viewYear, viewMonth-1, 1).getDay() + 6) % 7
    property int dimCurrent: new Date(viewYear, viewMonth, 0).getDate()
    property int dimPrev:    new Date(viewMonth === 1 ? viewYear-1 : viewYear,
                                      viewMonth === 1 ? 11 : viewMonth-1, 0).getDate()
    property int totalCells: firstDay + dimCurrent
    property int gridRows:   Math.ceil(totalCells / 7)

    property int popupGap: 10
    property int popupContentH: showYearPicker
                    ? 16 + 40 + 12 + 160 + 16
                    : 16 + 40 + 12 + (24 + 1 + gridRows * cellH + 14) + 16

    implicitHeight: popupContentH + popupGap

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open || calSlideAnim.running

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    property int  todayDay:      1
    property int  todayMonth:    1
    property int  todayYear:     2025
    property int  viewMonth:     todayMonth
    property int  viewYear:      todayYear
    property int  selectedDay:   -1
    property int  selectedMonth: -1
    property int  selectedYear:  -1
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
            }
        }
    }

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dayNames: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    function prevMonth() {
        if (viewMonth === 1) { viewMonth = 12; viewYear-- } else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 12) { viewMonth = 1; viewYear++ } else viewMonth++
    }

    // ── Fond glassmorphism ───────────────────────────────────────────────
    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: calPanel
            width: parent.width
            height: win.popupContentH
            radius: Theme.popupRadius
            color:  Theme.popupBg
            border.color: Theme.popupBorder
            border.width: Theme.popupBorderWidth

            y: win.open ? win.popupGap : -height
            Behavior on y { NumberAnimation { id: calSlideAnim; duration: 300; easing.type: Easing.OutQuart } }

        // Reflet glossy (z:0 = derrière le contenu)
        Rectangle {
            z: 0
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: parent.height * Theme.popupGlossHeight
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.popupGlossTop }
                GradientStop { position: 1.0; color: Theme.popupGlossBottom }
            }
        }

        // ── Contenu interactif (z:1 = au-dessus du glossy) ──────────────
        Column {
            z: 1
            anchors.fill:    parent
            anchors.margins: Theme.popupPadding + 2
            spacing:         12

            // ── En-tête : flèches + mois année ───────────────────────
            Item {
                width: parent.width; height: 40

                Rectangle {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32; radius: 9
                    color: prevMa.containsMouse ? Theme.popupPressed : Theme.popupHover
                    border.color: prevMa.containsMouse ? Theme.popupHoverBorder : Theme.popupBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Text {
                        anchors.centerIn: parent; text: "<"
                        color: Theme.popupFg
                        font.pixelSize: 14; font.family: Theme.font; font.bold: true
                    }
                    MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.prevMonth() }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: monthYearTxt.implicitWidth + 16; height: 32; radius: 9
                    color: yearHoverMa.containsMouse ? Theme.popupPressed : "transparent"
                    border.color: yearHoverMa.containsMouse ? Theme.popupHoverBorder : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Text {
                        id: monthYearTxt; anchors.centerIn: parent
                        text: win.monthNames[win.viewMonth - 1] + " " + win.viewYear
                        color: Theme.popupFg
                        font.family: Theme.font; font.pixelSize: 15; font.bold: true
                    }
                    MouseArea {
                        id: yearHoverMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.showYearPicker = !win.showYearPicker
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32; radius: 9
                    color: nextMa.containsMouse ? Theme.popupPressed : Theme.popupHover
                    border.color: nextMa.containsMouse ? Theme.popupHoverBorder : Theme.popupBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.popupAnimFast } }
                    Text {
                        anchors.centerIn: parent; text: ">"
                        color: Theme.popupFg
                        font.pixelSize: 14; font.family: Theme.font; font.bold: true
                    }
                    MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.nextMonth() }
                }
            }

            // ── Sélecteur d'année ────────────────────────────────────
            GridView {
                width: parent.width
                height: win.showYearPicker ? 160 : 0
                visible: win.showYearPicker
                clip: true
                cellWidth: parent.width / 4; cellHeight: 38
                model: 24
                property int startYear: win.todayYear - 6
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                delegate: Item {
                    required property int index
                    property int yr: GridView.view.startYear + index
                    width: GridView.view.cellWidth; height: GridView.view.cellHeight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4; radius: 8
                        color: yr === win.viewYear ? Theme.popupAccent
                             : yrMa.containsMouse  ? Theme.popupHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                        Text {
                            anchors.centerIn: parent; text: parent.parent.yr
                            color: yr === win.viewYear ? "#fff" : Qt.rgba(1,1,1, yr === win.todayYear ? 0.9 : 0.55)
                            font.family: Theme.font; font.pixelSize: 12; font.bold: yr === win.todayYear
                        }
                        MouseArea {
                            id: yrMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { win.viewYear = parent.parent.yr; win.showYearPicker = false }
                        }
                    }
                }
            }

            // ── Cadre grille ─────────────────────────────────────────
            Rectangle {
                visible: !win.showYearPicker
                width: parent.width
                height: 24 + 1 + win.gridRows * win.cellH + 14
                radius: Theme.popupInnerRadius
                color: Theme.popupInnerBg
                border.color: Theme.popupInnerBorder; border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 8; anchors.leftMargin: 8
                    anchors.rightMargin: 8; anchors.bottomMargin: 6
                    spacing: 0

                    Row {
                        width: parent.width
                        Repeater {
                            model: win.dayNames
                            Text {
                                required property string modelData
                                width: win.cellW; height: 24; text: modelData
                                color: Theme.popupFgMuted
                                font.pixelSize: 12; font.family: Theme.font; font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.popupSeparator }

                    Item {
                        width: parent.width; height: win.gridRows * win.cellH

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
                                    font.pixelSize: 14; font.family: Theme.font
                                }
                            }
                        }

                        Repeater {
                            model: win.dimCurrent
                            delegate: Item {
                                required property int index
                                property int offset: win.firstDay + index
                                property int col: offset % 7
                                property int row: Math.floor(offset / 7)
                                property int day: index + 1
                                property bool isToday: day === win.todayDay && win.viewMonth === win.todayMonth && win.viewYear === win.todayYear
                                property bool isSelected: day === win.selectedDay && win.viewMonth === win.selectedMonth && win.viewYear === win.selectedYear
                                property bool isWeekend: col >= 5

                                x: col * win.cellW; y: row * win.cellH
                                width: win.cellW; height: win.cellH

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 32; height: 32; radius: 9
                                    color: isSelected ? Theme.popupPressed
                                         : isToday ? Theme.popupAccentBright
                                         : dayMa.containsMouse ? Theme.popupHover
                                         : "transparent"
                                    border.color: isSelected ? Theme.popupHoverBorder : "transparent"
                                    border.width: isSelected ? 1 : 0
                                    Behavior on color { ColorAnimation { duration: Theme.popupAnimFast } }
                                    Text {
                                        anchors.centerIn: parent; text: parent.parent.day
                                        color: isSelected || isToday ? "#fff"
                                             : isWeekend ? Theme.popupFgMuted : Theme.popupFg
                                        font.pixelSize: 14; font.family: Theme.font
                                        font.bold: isToday || isSelected
                                    }
                                }
                                MouseArea {
                                    id: dayMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.selectedDay = day
                                        win.selectedMonth = win.viewMonth
                                        win.selectedYear = win.viewYear
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
