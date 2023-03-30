import QtQuick 2.7

//
// A KnobMapping positioned on the canvas
//
// Variables that need to exist in the scope:
// - unitSize : size * the main widget
// - legendSize : size of the legend below the widget
Item {
    id: root
    x: (mapping.knobNumber  % 8) * unitSize
    y: (unitSize + legendSize) * (~~(mapping.knobNumber / 8))

    //property string legend: ""

    property alias text: frame.text
    property alias legend: frame.legend

    property alias mapping: knob
    property alias value: knob.value

    property color color: "white"

    KnobMapping {
        id: knob

        /*Text {
            x: (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
            text: root.legend
        }*/
    }

    FramedText {
        id: frame
        color: root.color
    }
}
