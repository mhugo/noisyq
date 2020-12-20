import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

Item {
    id: root

    property real size: 64
    implicitWidth: root.size
    implicitHeight: root.size

    property string color : "black"
    Rectangle
    {
        width: root.size
        height: root.size
        radius: root.size/10
        color: {
            if (parent.color == "red") {
                "#d90243"
            }
            else if (parent.color == "green") {
                "#6fc22b"
            }
            else if (parent.color == "blue") {
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
