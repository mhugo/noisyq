import QtQuick 2.7
import QtQuick.Controls 2.5

Rectangle {
    id: root
    property real value: 0
    property real max: 1
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

        Rectangle {
            border.color: "black"
            border.width: 1
            width: parent.width * 0.3
            height: parent.height * 0.5
            x: (parent.width - width) / 2
            y: (parent.height - height) / 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: "red" }
                GradientStop { position: 0.3; color: "yellow" }
                GradientStop { position: 1.0; color: "green" }
            }

            Rectangle {
                border.color: "black"
                border.width: 1
                color: "white"
                width: parent.width
                height: (1.0 - root.value / root.max) * parent.height
            }
            Text {
                font.pixelSize: parent.height / 4
                text: ~~root.value
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
            }
        }

        Text {
            text: root.legend
            font.pixelSize: parent.height / 6
            x: (parent.width - width) / 2
            y: parent.height - height * 1.3
        }
    }
}
