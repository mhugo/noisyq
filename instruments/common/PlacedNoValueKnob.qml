import QtQuick 2.7

//
// A Knob with only increment and decrement
//
// Variables that need to exist in the scope:
// - unitSize : size * the main widget
// - legendSize : size of the legend below the widget
// - board
Item {
    id: root
    property int knobNumber: 0
    x: (knobNumber  % 8) * unitSize
    y: (unitSize + legendSize) * (~~(knobNumber / 8))

    Connections {
        target: board
        onKnobIncremented: {
            if (knobNumber == root.knobNumber) {
                root.onIncrement();
            }
        }
        onKnobDecremented: {
            if (knobNumber == root.knobNumber) {
                root.onDecrement();
            }
        }
        enabled: root.visible && root.enabled
    }
    function _initIfVisible() {
        if (visible) {
            board.setKnobHasValue(knobNumber, false);
        }
    }
    onVisibleChanged: {
        _initIfVisible();
    }
    Component.onCompleted: {
        _initIfVisible();
    }
}
