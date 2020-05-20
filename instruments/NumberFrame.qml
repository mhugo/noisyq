import QtQuick 2.0
import QtQuick.Controls 2.4

Rectangle {
    id: root
    property real value: 0
    property string text: ""
    property string unit: ""
    property bool displaySign: true

    property real size: main.unitSize

    width: size
    height: size

    Rectangle {
        width: root.size * 0.9
        height: root.size * 0.9
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
                    root.value + root.unit;
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
