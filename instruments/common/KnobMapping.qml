import QtQuick 2.0

//
// Helper to declare a knob mapping.
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
                infoScreen.flash(root.parameterDisplay + " = " + valueToString(amount));
                if (root.parameterName) {
                    lv2Host.setParameterValue(lv2Id, root.parameterName, root.value);
                }
            }
        }
        enabled: root.visible && root.enabled
    }

    function _initIfVisible() {
        if (visible) {
            board.setKnobIsInteger(root.knobNumber, root.isInteger);
            board.setKnobMinMax(root.knobNumber, root.min, root.max);
            board.setKnobValue(root.knobNumber, fromParameter(root.value));
        }
    }
    onVisibleChanged: {
        _initIfVisible();
    }
    Component.onCompleted: {
        _initIfVisible();
    }
}
