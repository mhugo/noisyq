import QtQuick 2.7
import QtQuick.Controls 2.5

Rectangle {
    id: root
    property real value: 0
    property real max: 0
    property string text: ""
    property string unit: ""
    property bool displaySign: true

    property real size: main.unitSize

    width: size
    height: size

    Rectangle {
        width: root.width * 0.9
        height: root.height * 0.9
        x: root.size * 0.05
        y: root.size * 0.05
        border.color: "black"
        border.width: 3
        radius: root.size / 10

        Text {
            text: {
                if (displaySign)
                    root.value > 0 ? "+" + root.value + root.unit : root.value + root.unit;
                else
                    root.value + (root.max > 0 ? ("/" + root.max) : "") + root.unit;
            }
            font.pixelSize: parent.height / 3
            font.family: monoFont.name
            x: (parent.width - width) / 2
            y: (parent.height - height) / 3
        }
        Text {
            text: root.text
            font.pixelSize: parent.height / 6
            x: (parent.width - width) / 2
            y: parent.height - height * 1.3
        }
    }
}
