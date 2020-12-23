import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

Item {
    id: root

    property real size: 64
    implicitWidth: root.size
    implicitHeight: root.size

    enum Color {
        Black,
        Red,
        Green,
        Blue,
        White
    }

    property string color : Pad.Color.Black
    Rectangle
    {
        width: root.size
        height: root.size
        radius: root.size/10
        color: {
            if (parent.color == Pad.Color.Red) {
                "#d90243"
            }
            else if (parent.color == Pad.Color.Green) {
                "#6fc22b"
            }
            else if (parent.color == Pad.Color.Blue) {
                "#2f9af7"
            }
            else {
                "white"
            }
        }
        Image {
            y: parent.y + parent.radius
            x: parent.x + parent.radius
            source: "pad.svg"
            sourceSize.width: root.size - parent.radius*2
            sourceSize.height: root.size - parent.radius*2
        }
    }
}
