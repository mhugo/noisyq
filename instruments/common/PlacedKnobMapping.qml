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

    property string legend: ""

    property alias mapping: knob
    property alias value: knob.value
    property alias shiftValue: knob.shiftValue

    KnobMapping {
        id: knob

        Text {
            x: (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
            text: root.legend
        }
    }
}
