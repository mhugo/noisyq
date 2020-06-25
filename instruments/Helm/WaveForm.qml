import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

Rectangle {
    id: root
    property int value: 0
    property int count: waveEnum.length

    property real size

    property var waveEnum : ["sin",
                             "triangle",
                             "square",
                             "saw up",
                             "saw down",
                             "3 step",
                             "4 step",
                             "8 step",
                             "3 pyramid",
                             "5 pyramid",
                             "9 pyramid"]

    property int from: 0
    property int to: count-1

    width: size
    height: size

    Repeater {
        id: rep
        model: waveEnum
        Rectangle {
            width: root.size * 0.9
            height: root.size * 0.9
            x: root.size * 0.05
            y: root.size * 0.05        
            border.width: 3
            border.color: "black"
            color: "black"
            radius: root.size / 10

            visible: root.value == index
            Image {
                width: parent.width * 0.9
                height: parent.height * 0.9
                x: width * 0.05
                y: width * 0.05
                source: "helm_waves/" + modelData.replace(" ", "_") + ".png"
            }
            Text {
                text: modelData
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                color: "white"
            }
        }
    }
}

