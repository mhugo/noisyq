import QtQuick 2.7
import QtQuick.Controls 2.5

Rectangle {
    id: root
    property string text: ""
    property string legend: ""
    property int unitWidth: 1
    property int unitHeight: 1
    property color color: "white"

    width: main.unitSize * unitWidth
    height: main.unitSize * unitHeight

    Rectangle {
        id: r
        width: root.width - main.unitSize * 0.1
        height: root.height - main.unitSize * 0.1
        x: main.unitSize * 0.05
        y: main.unitSize * 0.05
        border.color: "black"
        border.width: 3
        radius: main.unitSize / 10
        color: root.color

        Text {
            text: root.text
            font.pixelSize: parent.height / 3
            font.family: monoFont.name
            x: (parent.width - width) / 2
            y: (parent.height - height) / 3
        }

        Text {
            text: root.legend
            font.pixelSize: parent.height / 6
            x: (parent.width - width) / 2
            y: parent.height - height * 1.3
        }
    }
}
