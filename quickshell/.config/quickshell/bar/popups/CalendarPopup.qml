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
    margins.top:  Theme.barHeight + 6
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

    implicitHeight: showYearPicker
                    ? 16 + 40 + 12 + 160 + 16
                    : 16 + 40 + 12 + (24 + 1 + gridRows * cellH + 14) + 16

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows:  true
    visible:       open

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

    // ── Fond glassmorphism principal ──────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       18
        color:        Qt.rgba(22/255, 14/255, 32/255, 0.70)
        border.color: Qt.rgba(1,1,1,0.10)
        border.width: 1
        clip:         true

        opacity: win.open ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Reflet glossy haut
        Rectangle {
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: parent.height * 0.45
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.07) }
                GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
            }
        }

        Column {
            anchors.fill:         parent
            anchors.margins:      16
            spacing:              12

            // ── En-tête : flèches + mois année ───────────────────────────
            Item {
                width: parent.width; height: 40

                // Flèche gauche
                Rectangle {
                    anchors.left:           parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32; radius: 9
                    color: prevMa.containsMouse
                           ? Qt.rgba(1,1,1,0.28)
                           : Qt.rgba(1,1,1,0.10)
                    border.color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.35) : Qt.rgba(1,1,1,0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent; text: "<"
                        color: "#FFFFFF"
                        font.pixelSize: 14; font.family: Theme.font; font.bold: true
                    }
                    MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.prevMonth() }
                }

                // Mois + année
                Rectangle {
                    anchors.centerIn: parent
                    width:  monthYearTxt.implicitWidth + 16
                    height: 32; radius: 9
                    color:  yearHoverMa.containsMouse ? Qt.rgba(1,1,1,0.28) : "transparent"
                    border.color: yearHoverMa.containsMouse ? Qt.rgba(1,1,1,0.35) : "transparent"
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Text {
                        id: monthYearTxt
                        anchors.centerIn: parent
                        text: win.monthNames[win.viewMonth - 1] + " " + win.viewYear
                        color: "#FFFFFF"
                        font.family: Theme.font; font.pixelSize: 15; font.bold: true
                    }
                    MouseArea {
                        id: yearHoverMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: win.showYearPicker = !win.showYearPicker
                    }
                }

                // Flèche droite
                Rectangle {
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32; radius: 9
                    color: nextMa.containsMouse
                           ? Qt.rgba(1,1,1,0.28)
                           : Qt.rgba(1,1,1,0.10)
                    border.color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.35) : Qt.rgba(1,1,1,0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent; text: ">"
                        color: "#FFFFFF"
                        font.pixelSize: 14; font.family: Theme.font; font.bold: true
                    }
                    MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.nextMonth() }
                }
            }

            // ── Sélecteur d'année ─────────────────────────────────────────
            GridView {
                width:   parent.width
                height:  win.showYearPicker ? 160 : 0
                visible: win.showYearPicker
                clip:    true
                cellWidth:  parent.width / 4
                cellHeight: 38
                model: 24
                property int startYear: win.todayYear - 6
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                delegate: Item {
                    required property int index
                    property int yr: GridView.view.startYear + index
                    width: GridView.view.cellWidth; height: GridView.view.cellHeight

                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4; radius: 8
                        color: yr === win.viewYear ? Qt.rgba(163/255,35/255,53/255,0.55)
                             : yrMa.containsMouse  ? Qt.rgba(1,1,1,0.10)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
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

            // ── Cadre semi-transparent encadrant toute la grille ──────────
            Rectangle {
                visible:      !win.showYearPicker
                width:        parent.width
                height:       24 + 1 + win.gridRows * win.cellH + 14
                radius:       12
                color:        Qt.rgba(1,1,1,0.07)
                border.color: Qt.rgba(1,1,1,0.10)
                border.width: 1

                Column {
                    anchors.fill:         parent
                    anchors.topMargin:    8
                    anchors.leftMargin:   8
                    anchors.rightMargin:  8
                    anchors.bottomMargin: 6
                    spacing: 0

                    // Labels jours semaine
                    Row {
                        width: parent.width
                        Repeater {
                            model: win.dayNames
                            Text {
                                required property string modelData
                                width:  win.cellW; height: 24
                                text:   modelData
                                color:  Qt.rgba(1,1,1,0.40)
                                font.pixelSize: 12; font.family: Theme.font; font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                            }
                        }
                    }

                    // Séparateur
                    Rectangle {
                        width: parent.width; height: 1
                        color: Qt.rgba(1,1,1,0.08)
                    }

                    // Grille
                    Item {
                        width:  parent.width
                        height: win.gridRows * win.cellH

                        // Jours mois précédent (grisés)
                        Repeater {
                            model: win.firstDay
                            delegate: Item {
                                required property int index
                                x: index * win.cellW
                                y: 0
                                width: win.cellW; height: win.cellH

                                Text {
                                    anchors.centerIn: parent
                                    text:  win.dimPrev - win.firstDay + 1 + index
                                    color: Qt.rgba(1,1,1,0.18)
                                    font.pixelSize: 14; font.family: Theme.font
                                }
                            }
                        }

                        // Jours mois courant
                        Repeater {
                            model: win.dimCurrent
                            delegate: Item {
                                required property int index
                                property int offset:     win.firstDay + index
                                property int col:        offset % 7
                                property int row:        Math.floor(offset / 7)
                                property int day:        index + 1
                                property bool isToday:   day === win.todayDay && win.viewMonth === win.todayMonth && win.viewYear === win.todayYear
                                property bool isSelected:day === win.selectedDay && win.viewMonth === win.selectedMonth && win.viewYear === win.selectedYear
                                property bool isWeekend: col >= 5

                                x: col * win.cellW
                                y: row * win.cellH
                                width:  win.cellW
                                height: win.cellH

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 32; height: 32; radius: 9
                                    color: isSelected ? Qt.rgba(1,1,1,0.28)
                                         : isToday    ? Qt.rgba(163/255,35/255,53/255,0.65)
                                         : dayMa.containsMouse ? Qt.rgba(1,1,1,0.10)
                                         : "transparent"
                                    border.color: isSelected ? Qt.rgba(1,1,1,0.25) : "transparent"
                                    border.width: isSelected ? 1 : 0
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text:  parent.parent.day
                                        color: isSelected || isToday ? "#fff"
                                             : isWeekend ? Qt.rgba(1,1,1,0.42)
                                             : Qt.rgba(1,1,1,0.88)
                                        font.pixelSize: 14; font.family: Theme.font
                                        font.bold: isToday || isSelected
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
                }
            }
        }
    }
}
