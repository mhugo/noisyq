import QtQuick 2.7
import QtQuick.Controls 2.5

Rectangle {
    id: root
    property string text: ""
    property string legend: ""
    property real size: main.unitSize

    width: size
    height: size

    Rectangle {
        id: r
        width: root.width * 0.9
        height: root.height * 0.9
        x: root.size * 0.05
        y: root.size * 0.05
        border.color: "black"
        border.width: 3
        radius: root.size / 10

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
