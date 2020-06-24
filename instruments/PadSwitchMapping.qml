import QtQuick 2.0

//
// Helper to declare a pad "switch" mapping. The pad has two states: on/off, represented by a boolean.
Item {
    id: root

    property int padNumber: 0

    property bool value: false

    // Value used by the plugin to represent the "off" state
    property real valueOff: 0.0
    // Value used by the plugin to represent the "on" state
    property real valueOn: 1.0

    // Parameter name
    property string parameterName

    // Human-centered parameter name
    property string parameterDisplay: parameterName

    // Called when converting from the value to the parameter value.
    // The default behaviour can be changed by redefining this function.
    function toParameter(v) {
        return v ? valueOn : valueOff;
    }

    // Called when converting from the parameter value to the value.
    // The default behaviour can be changed by redefining this function.
    function fromParameter(v) {
        return v == valueOn;
    }

    function valueToString(v) {
        return v ? "ON" : "OFF";
    }

    Connections {
        target: board
        onPadReleased: {
            if (padNumber == root.padNumber) {
                root.value = ! root.value;
                board.setPadColor(root.padNumber, root.value ? "green" : "white");
                infoScreen.text = root.parameterDisplay + " = " + valueToString(root.value);
                lv2Host.setParameterValue(lv2Id, root.parameterName, toParameter(root.value));
            }
        }
        enabled: root.visible
    }

    onVisibleChanged: {
        if (visible) {
            board.setPadColor(root.padNumber, root.value ? "green" : "white");
        }
    }
}
