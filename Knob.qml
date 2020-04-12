import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

ColumnLayout {
    id: root
    
    property alias value: dial.value

    property alias parameterMin: binding.parameterMin
    property alias parameterMax: binding.parameterMax

    property int floatKnob : 0
    property int intKnob: 1
    property int enumKnob: 2
    property int type: floatKnob

    property real displayedFrom: parameterMin
    property real displayedTo: parameterMax
    property var displayedValue

    property var enums

    property alias bindingSignal: binding.signalName
    property alias bindingParameter: binding.parameterName

    signal keyPressed(int code, int key, int modifiers)
    signal keyReleased(int code, int key, int modifiers)

    function _clamp(v, min, max) {
        if ( v > max )
            v = max;
        if ( v < min )
            v = min;
        return v;
    }
    onKeyPressed: {
        console.log("knob keypressed", value);
        let v;
        if (type == floatKnob) {
            if (code == keycode.k_up) {
                if ( modifiers & Qt.ShiftModifier )
                    v = value + .01 * (displayedTo - displayedFrom);
                else
                    v = value + .1 * (displayedTo - displayedFrom);
                value = _clamp(v, displayedFrom, displayedTo);
            }
            else if (code == keycode.k_down) {
                if ( modifiers & Qt.ShiftModifier )
                    v = value - .01 * (displayedTo - displayedFrom);
                else
                    v = value - .1 * (displayedTo - displayedFrom);
                value = _clamp(v, displayedFrom, displayedTo);
            }
        }
        else {
            if (code == keycode.k_up) {
                v = value + 1;
                value = _clamp(v, dial.from, dial.to);
            }
            else if (code == keycode.k_down) {
                v = value - 1;
                value = _clamp(v, dial.from, dial.to);
            }
        }
    }
    onKeyReleased: {
        childItem.data[0].keyReleased(code, key, modifiers);
    }

    Dial {
        id: dial
        from: root.type == enumKnob ? 0 : root.displayedFrom
        to: root.type == enumKnob ? root.enums.length - 1 : root.displayedTo
        snapMode: root.type == floatKnob ? Dial.NoSnap : Dial.SnapAlways
        stepSize: root.type == floatKnob ? 0 : 1
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64

        Text {
            text: {
                if (value === undefined)
                    "?";
                else if (root.type == root.floatKnob) {
                    value.toFixed(2);
                }
                else if (root.type == root.enumKnob) {
                    if (root.enums !== undefined)
                        root.enums[~~value];
                    else
                        "?";
                }
                else {
                    ~~value;
                }
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
        }
    }
    BindingDeclaration {
        id: binding
        propertyName: "value"
        signalName: "valueChanged"
        propertyMin: parent.displayedFrom
        propertyMax: parent.displayedTo
    }
}
