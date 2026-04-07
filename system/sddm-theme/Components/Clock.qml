import QtQuick 2.11
import QtQuick.Controls 2.4

Column {
    id: clock
    spacing: 5
    width: parent.width

    Label {
        id: timeLabel
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: root.font.family
        font.pointSize: 48 
        font.bold: true
        color: root.palette.text        // Tu #FEFEFE blanco puro
        renderType: Text.QtRendering
    }

    Label {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: root.font.family
        font.pointSize: 12
        color: root.palette.highlight   // Tu amarillo #C4C700
        renderType: Text.QtRendering
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var d = new Date()
            timeLabel.text = Qt.formatTime(d, "HH:mm") // Formato militar 24hs
            dateLabel.text = Qt.formatDate(d, "dddd, dd MMMM").toUpperCase()
        }
    }

    Component.onCompleted: {
        var d = new Date()
        timeLabel.text = Qt.formatTime(d, "HH:mm")
        dateLabel.text = Qt.formatDate(d, "dddd, dd MMMM").toUpperCase()
    }
}