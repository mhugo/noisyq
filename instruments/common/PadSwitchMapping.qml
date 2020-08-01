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

    function _updatePad() {
        board.setPadColor(root.padNumber, root.value ? "green" : "white");
        padMenu.updateText(
            root.padNumber,
            root.parameterDisplay + "\n" + valueToString(root.value)
        );
    }

    Connections {
        target: board
        onPadReleased: {
            console.log("padswitch on pad released");
            if (padNumber == root.padNumber) {
                root.value = ! root.value;
                _updatePad();
                infoScreen.text = root.parameterDisplay + " = " + valueToString(root.value);
                lv2Host.setParameterValue(lv2Id, root.parameterName, toParameter(root.value));
            }
        }
        enabled: root.visible && root.enabled
    }

    onVisibleChanged: {
        if (visible) {
            _updatePad();
        }
    }
}
