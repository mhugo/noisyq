import QtQuick 2.7
import QtQuick.Controls 2.5

Text {
    id: root

    signal padPressed(int padNumber)
    signal padReleased(int padNumber)
    signal knobMoved(int knobNumber, real amount)

    property int selectedKnob : 0

    signal notePressed(int note, int velocity)
    signal noteReleased(int note)

    signal octaveUp()
    signal octaveDown()

    Repeater {
        id: knobs
        model: 16
        Item {
            property real value: 0
            property bool isInteger: false
            property real min: 0.0
            property real max: 1.0

            function _delta() {
                let d = max - min;
                if (isInteger) {
                    return d < 128 ? d / 128 : 1;
                }
                return d / 128.0;
            }

            function increment(amount) {
                console.log("inc, amount", amount);
                value = value + (amount ? amount : _delta());
                if (value > max) {
                    value = max;
                }
            }
            function decrement(amount) {
                value = value - (amount ? amount : _delta());
                if (value < min) {
                    value = min;
                }
            }
        }
    }

    Repeater {
        id: pads
        model: 16
        Item {
            property string color: "white"
        }
    }

    readonly property int knob1SwitchId : 16
    readonly property int knob9SwitchId : 17

    function knobValue(knobNumber) {
        let knob = knobs.itemAt(knobNumber);
        return knob ? knob.value : 0;
    }

    function setKnobValue(knobNumber, value) {
        let knob = knobs.itemAt(knobNumber);
        knob.value = value;
    }

    function setKnobMinMax(knobNumber, min, max) {
        knobs.itemAt(knobNumber).min = min;
        knobs.itemAt(knobNumber).max = max;
    }

    function setKnobIsInteger(knobNumber, isInteger) {
        console.log("knob", knobNumber, "isInteger", isInteger);
        knobs.itemAt(knobNumber).isInteger = isInteger;
    }

    function padColor(padNumber) {
        let item = pads.itemAt(padNumber);
        if (item === null)
            return "white";
        return item.color;
    }
    function setPadColor(padNumber, color) {
        pads.itemAt(padNumber).color = color;
    }

    // debug display
    text: "Knob " + selectedKnob + ": " + knobValue(selectedKnob).toFixed(2)
    font.family: titleFont.name
    font.pointSize: 14
    focus: true

    Keys.onPressed : {
        if ((event.key == Qt.Key_Up) || (event.key == Qt.Key_Down)) {
            let knob = knobs.itemAt(selectedKnob);
            if (event.key == Qt.Key_Up) {
                knob.increment(knob.isInteger ? 1 : 0);
            }
            else {
                knob.decrement(knob.isInteger ? 1 : 0);
            }
            knobMoved(selectedKnob, knob.value);
        }

        // isAutoRepeat only for pads, not for knobs +/-
        if (event.isAutoRepeat) {
            return;
        }
        console.log("key", "scan code", event.nativeScanCode, "key", event.key, "modifier", event.modifiers);
        let value;
        // ctrl + 0 => knob 1 switch
        if ((event.nativeScanCode == 10) && (event.modifiers & Qt.ControlModifier)) {
            padPressed(knob1SwitchId);
        }
        // ctrl + a => knob 9 switch
        else if ((event.nativeScanCode == 24) && (event.modifiers & Qt.ControlModifier)) {
            padPressed(knob9SwitchId);
        }
        // 12345...
        else if (event.nativeScanCode >= 10 && event.nativeScanCode < 18) {
            selectedKnob = event.nativeScanCode - 10;
        }
        // azerty..
        else if (event.nativeScanCode >= 24 && event.nativeScanCode < 32) {
            selectedKnob = event.nativeScanCode - 24 + 8;
        }
        // qsdfg...
        else if (event.nativeScanCode >= 38 && event.nativeScanCode < 46) {
            let padNumber = event.nativeScanCode - 38;
            if (event.modifiers & Qt.ControlModifier) {
                padPressed(padNumber + 8);
            }
            else {
                padPressed(padNumber);
            }
        }
        // wxcvbn.. => piano
        else if (event.nativeScanCode >= 52 && event.nativeScanCode < 62) {
            let key = event.nativeScanCode - 52 + 60;
            notePressed(key, 127);
        }
        else if (event.text == ">") {
            octaveUp();
        }
        else if (event.text == "<") {
            octaveDown();
        }
        else if (event.key == Qt.Key_Escape) {
            // escape
            quit();
        }
    }
    Keys.onReleased : {
        if (event.isAutoRepeat) {
            return;
        }
        // ctrl + 0 => knob 1 switch
        if ((event.nativeScanCode == 10) && (event.modifiers & Qt.ControlModifier)) {
            console.log("knob 1 switch");
            padReleased(knob1SwitchId);           
        }
        // ctrl + a => knob 9 switch
        else if ((event.nativeScanCode == 24) && (event.modifiers & Qt.ControlModifier)) {
            padReleased(knob9SwitchId);
        }
        else if (event.nativeScanCode >= 38 && event.nativeScanCode < 46) {
            let padNumber = event.nativeScanCode - 38;
            if (event.modifiers & Qt.ControlModifier) {
                padReleased(padNumber + 8);
            }
            else {
                padReleased(padNumber);
            }
        }
        else if (event.nativeScanCode >= 52 && event.nativeScanCode < 62) {
            let key = event.nativeScanCode - 52 + 60;
            noteReleased(key);
        }
    }

    Connections {
        target: midi
        onMidiReceived: {
            const cc_to_knob = {
                7: 0,
                8: 1,
                9: 2,
                10: 3,
                11: 4,
                12: 5,
                13: 6,
                14: 7,
                15: 8,
                16: 9,
                17: 10,
                18: 11,
                19: 12,
                20: 13,
                21: 14,
                22: 15
            };
            const cc_to_pad = {
                23: 0,
                24: 1,
                25: 2,
                26: 3,
                27: 4,
                28: 5,
                29: 6,
                30: 7,
                31: 8,
                64: 9,
                65: 10,
                66: 11,
                67: 12,
                68: 13,
                69: 14,
                70: 15,
                71: 16, // Knob 1 button
                72: 17  // Knob 9 button
            }
            console.log("+++ midi received", message);
            if ((message[0] & 0xF0) == 0x90) {
                // NOTE_ON
                console.log("note on");
                root.notePressed(message[1], message[2]);
            }
            else if ((message[0] & 0xF0) == 0x80) {
                // NOTE_OFF
                root.noteReleased(message[1]);
            }
            else if ((message[0] & 0xF0) == 0xB0) {
                // CC
                let cc = message[1];
                let v = message[2];
                if ((cc in cc_to_knob) && (v != 0x40)) {
                    const knobNumber = cc_to_knob[cc];
                    let amount = v - 0x40;
                    if (amount > 0) {
                        for (var i = 0; i < amount; i++)
                            knobs.itemAt(knobNumber).increment();
                        root.knobMoved(knobNumber, knobs.itemAt(knobNumber).value);
                    }
                    else if (amount < 0) {
                        for (var i = 0; i < -amount; i++)
                            knobs.itemAt(knobNumber).decrement();
                        root.knobMoved(knobNumber, knobs.itemAt(knobNumber).value);
                    }
                }
                if (cc in cc_to_pad) {
                    const padNumber = cc_to_pad[cc];
                    if (v == 0x7F)
                        root.padPressed(padNumber);
                    else
                        root.padReleased(padNumber);
                }
            }
            // TODO SYSEX
        }
    }
}
