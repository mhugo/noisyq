import QtQuick 2.0

//
// Helper to declare a knob mapping. It must be a direct child of the parameter it maps.
// The parent item must have the following properties defined:
// - value: the "internal" value, that can be different from the value manipulated by the knob.
//          For instance a knob with integer values can be mapped to a real value in [0,1]
Item {
    id: root

    property bool isInteger: false
    property real value: 0.0
    property real min: 0.0
    property real max: 1.0
    property int knobNumber: 0

    // Parameter name
    property string parameterName

    // Human-centered parameter name
    property string parameterDisplay: parameterName

    // Called when converting from the knob value to the internal value.
    // The default behaviour can be changed by redefining this function.
    function toParameter(v) {
        return v;
    }

    // Called when converting from the internal value to the knob value.
    // The default behaviour can be changed by redefining this function.
    function fromParameter(v) {
        return v;
    }

    function valueToString(v) {
        return isInteger ? v.toString() : v.toFixed(2);
    }

    Connections {
        target: board
        onKnobMoved: {
            if (knobNumber == root.knobNumber) {
                root.value = toParameter(amount);
                // TODO infoScreen
                infoScreen.text = root.parameterDisplay + " = " + valueToString(amount);
                lv2Host.setParameterValue(lv2Id, root.parameterName, root.value);
            }
        }
        enabled: root.visible
    }

    onVisibleChanged: {
        if (visible) {
            board.setKnobIsInteger(root.knobNumber, root.isInteger);
            board.setKnobMinMax(root.knobNumber, root.min, root.max);
            board.setKnobValue(root.knobNumber, fromParameter(root.value));
        }
    }
}
