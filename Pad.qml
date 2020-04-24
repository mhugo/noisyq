import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

Item {
    id: root
    width: 64
    height: 64

    property string color : "black"
    Rectangle
    {
        width: root.width
        height: root.height
        radius: 6
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
            y: parent.y + 6
            x: parent.x + 6
            source: "pad.svg"
            sourceSize.width: root.width - 12
            sourceSize.height: root.height - 12
        }
    }
}
