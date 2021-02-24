import QtQuick 2.7
import QtQuick.Controls 2.5

//
// A Dial positioned on the canvas
//
// Variables that need to exist in the scope:
// - unitSize : size * the main widget
// - legendSize : size of the legend below the widget
Item {
    id: root

    property int knobNumber: 0
    property bool isInteger: false
    property var enumValues: []

    property real value: 0.0
    property real min: 0.0
    property real max: enumValues ? enumValues.length - 1: 1.0


    x: (knobNumber  % 8) * unitSize
    y: (unitSize + legendSize) * (~~(knobNumber / 8))

    property string legend: ""

    Dial {
        width: unitSize
        height: unitSize
        value: parent.value
        from: parent.min
        to: parent.max
        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                if (root.enumValues.length > 0) {
                    root.enumValues[~~value]
                }
                else if (isInteger) {
                    ~~value
                }
                else {
                    value
                }
            }
        }
    }
    Text {
        x: (unitSize - width) / 2
        y: unitSize + (legendSize - height) / 2
        text: root.legend
    }

    Connections {
        target: board
        onKnobMoved: {
            if (knobNumber == root.knobNumber) {
                if (amount <= root.max)
                    root.value = amount;
            }
        }
        enabled: root.visible && root.enabled
    }

    function _initIfVisible() {
        if (visible) {
            board.setKnobIsInteger(root.knobNumber, (root.enumValues.length > 0) || root.isInteger);
            board.setKnobMinMax(root.knobNumber, root.min, root.max);
            board.setKnobValue(root.knobNumber, root.value);
        }
    }
    onVisibleChanged: {
        _initIfVisible();
    }
    Component.onCompleted: {
        _initIfVisible();
    }
    
}
