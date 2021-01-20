import QtQuick 2.7
import QtQuick.Layouts 1.11

Item {
    id: root
    property int octave: 4

    readonly property int octaveWidth: unitSize

    height: main.unitSize*1.5

    // note index -> corresponding Rectangle for key
    property var _keyForNote: ({})

    // 
    function noteOn(note, velocity) {
        _keyForNote[note].color = "grey";
    }
    function noteOff(note) {
        _keyForNote[note].color = _keyForNote[note].initialColor;
    }

    Item {
        id: pianoK
        width: main.width - octaveWidth
        height: main.unitSize*1.5 - 32
        y: 16
        property real keyWidth: (main.width - octaveWidth) / 15

        Repeater {
            id: whiteKeyRep
            model: 15
            property var semis : [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24]
            Rectangle {
                x: (index * pianoK.keyWidth)
                y: parent.y
                width: pianoK.keyWidth
                height: parent.height
                border.width: 1
                Layout.margins: 0
                border.color: "black"
                property string initialColor: "white"
                color: initialColor
            }
        }
        Repeater {
            id: blackKeyRep
            model: [0, 1, 3, 4, 5, 7, 8, 10, 11, 12]
            property var semis : [1, 3, 6, 8, 10, 13, 15, 18, 20, 22]
            Rectangle {
                x: ((modelData+0.75) * pianoK.keyWidth)
                y: parent.y
                width: pianoK.keyWidth / 2
                height: parent.height / 2
                border.width: 1
                Layout.margins: 0
                border.color: "black"
                property string initialColor: "black"
                color: initialColor
            }
        }

        Component.onCompleted : {
            for (var i = 0; i < whiteKeyRep.semis.length; i++) {
                parent._keyForNote[whiteKeyRep.semis[i]] = whiteKeyRep.itemAt(i);
            }
            for (var i = 0; i < blackKeyRep.semis.length; i++) {
                parent._keyForNote[blackKeyRep.semis[i]] = blackKeyRep.itemAt(i);
            }
        }
    }
    Text {
        id: octaveText
        width: octaveWidth
        text: "Octave\n" + parent.octave
        horizontalAlignment: Text.AlignHCenter
        y: (unitSize * 1.5 - height) / 2
        x: main.width - octaveWidth + (octaveWidth - width) / 2
    }
}
