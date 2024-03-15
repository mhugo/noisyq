import QtQuick 2.7
import QtQuick.Controls 2.5

Text {
    id: root

    readonly property int doubleTapMaxTimeMs: 250

    signal padPressed(int padNumber)
    signal padReleased(int padNumber)
    signal padDoubleTapped(int padNumber)
    signal knobMoved(int knobNumber, real amount)
    signal knobIncremented(int knobNumber)
    signal knobDecremented(int knobNumber)

    property int selectedKnob : 0

    signal notePressed(int note, int velocity)
    signal noteReleased(int note)

    signal octaveUp()
    signal octaveDown()

    property bool isShiftPressed: false
    signal shiftPressed()
    signal shiftReleased()

    property bool debugEnabled: false

    signal keyUp()
    signal keyDown()
    signal keyLeft()
    signal keyRight()

    enum Color {
        Black,
        Red,
        Green,
        Yellow,
        Blue,
        Purple,
        Cyan,
        White
    }

    Repeater {
        id: knobs
        model: 17
        // knob #16 : modulation wheel
        Item {
            property real value: 0
            property bool isInteger: false
            property real min: 0.0
            property real max: 1.0

            // hasValue = false => value is meaningless and we are only
            // interested in increment and decrement signals
            property bool hasValue: true

            // For integer properties, incrementing / decrementing them for each small increment / decrement
            // of the knob value is changing too quickly
            // We could increment by a small decimal value, but not all VST correctly supports that.
            // Instead, we introduce here an internal ("proxy") value that is changed when the knob moves;
            // but the real value sent to the VST is always an integer
            property real internalValue: 0.0

            /*function _delta() {
                let d = max - min;
                if (isInteger) {
                    return d < 128 ? d / 128 : 1;
                }
                return d / 128.0;
            }*/
            function _delta() {
                let d = max - min;
                return isInteger ? 0.05 : d / 128.0;
            }

            function increment(amount) {
                if (isInteger) {
                    internalValue = internalValue + (amount ? amount : _delta());
                    if (internalValue > max) {
                        internalValue = max;
                    }
                    if (Math.abs(value - internalValue) >= 1.0) {
                        value = Math.floor(internalValue);
                    }
                }
                else {
                    value = value + (amount ? amount : _delta());
                    if (value > max) {
                        value = max;
                    }
                }
            }
            function decrement(amount) {
                if (isInteger) {
                    internalValue = internalValue - (amount ? amount : _delta());
                    if (internalValue < min) {
                        internalValue = min;
                    }
                    if (Math.abs(value - internalValue) >= 1.0) {
                        value = Math.floor(internalValue);
                    }
                }
                else {
                    value = value - (amount ? amount : _delta());
                    if (value < min) {
                        value = min;
                    }
                }
            }
        }
    }

    readonly property int knobModulationId : 16

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

    function setKnobHasValue(knobNumber, hasValue) {
        knobs.itemAt(knobNumber).hasValue = hasValue;
    }

    function incrementKnob(knobNumber, amount) {
        let knob = knobs.itemAt(knobNumber);
        knob.increment(amount);
        knobMoved(knobNumber, knob.value);
    }
    function decrementKnob(knobNumber, amount) {
        let knob = knobs.itemAt(knobNumber);
        knob.decrement(amount);
        knobMoved(knobNumber, knob.value);
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
    text: ("Knob " + selectedKnob + ": " + knobValue(selectedKnob).toFixed(2)
           + " | debug(o): " + (debugEnabled ? "ON": "OFF")
           + " | last row(p): " + (_pianoSelected ? "piano" : "8-16 pads"))
    font.family: titleFont.name
    font.pointSize: 14
    focus: true

    property bool _pianoSelected: false
    property int currentOctave: 4

    function _scancodeToMidiKey(scancode) {
        // Convert a scan code in the two rows qsdfg and wxcvb to a MIDI keyboard key number
        let whiteKeys = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24];
        let blackKeys = [-1, 1, 3, -1, 6, 8, 10, -1, 13, 15, -1, 18, 20, 22];
        if (scancode >= 52 && scancode < 62) // wxcvb => white keys
            return whiteKeys[scancode - 52];
        if (scancode >= 38 && scancode < 50) { // qsdfg => black keys
            return blackKeys[scancode - 38];
        }
    }

    Keys.onPressed : {
        if ((event.key == Qt.Key_PageUp) || (event.key == Qt.Key_PageDown)) {
            let knob = knobs.itemAt(selectedKnob);
            if (event.key == Qt.Key_PageUp) {
                if (knob.hasValue) {
                    knob.increment(knob.isInteger ? 1 : 0);
                } else {
                    knobIncremented(selectedKnob);
                }
            }
            else {
                if (knob.hasValue) {
                    knob.decrement(knob.isInteger ? 1 : 0);
                } else {
                    knobDecremented(selectedKnob);
                }
            }
            if (knob.hasValue)
                knobMoved(selectedKnob, knob.value);
        }
        else if (event.key == Qt.Key_Up) {
            keyUp();
        }
        else if (event.key == Qt.Key_Down) {
            keyDown();
        }
        else if (event.key == Qt.Key_Left) {
            keyLeft();
        }
        else if (event.key == Qt.Key_Right) {
            keyRight();
        }

        // isAutoRepeat only for pads, not for knobs +/-
        if (event.isAutoRepeat) {
            return;
        }
        console.log("key pressed", "scan code", event.nativeScanCode, "key", event.key, "modifier", event.modifiers);

        if (event.modifiers & Qt.ShiftModifier) {
            shiftPressed();
            isShiftPressed = true;
        }
        let value;
        // ctrl + 0 => knob 1 switch
        if ((event.nativeScanCode == 10) && (event.modifiers & Qt.ControlModifier)) {
            padPressed(knob1SwitchId);
        }
        // ctrl + a => knob 9 switch
        else if ((event.nativeScanCode == 24) && (event.modifiers & Qt.ControlModifier)) {
            padPressed(knob9SwitchId);
        }
        // ^2 => modulation wheel
        else if (event.nativeScanCode == 49) {
            selectedKnob = knobModulationId;
        }
        // 12345...
        else if (event.nativeScanCode >= 10 && event.nativeScanCode < 18) {
            selectedKnob = event.nativeScanCode - 10;
        }
        // azerty..
        else if (event.nativeScanCode >= 24 && event.nativeScanCode < 32) {
            selectedKnob = event.nativeScanCode - 24 + 8;
        }
        else if (event.text == "o") {
            debugEnabled = ! debugEnabled;
        }
        else if (event.text == "p") {
            _pianoSelected = ! _pianoSelected;
        }
        // qsdfg...
        else if (!_pianoSelected && (event.nativeScanCode >= 38 && event.nativeScanCode < 46)) {
            let padNumber = event.nativeScanCode - 38;
            if (event.modifiers & Qt.ControlModifier) {
                padPressed(padNumber + 8);
            }
            else {
                padPressed(padNumber);
            }
        }
        else if (_pianoSelected && (event.nativeScanCode >= 38 && event.nativeScanCode < 50)) {
            let midiKey = _scancodeToMidiKey(event.nativeScanCode);
            if (midiKey != -1)
                notePressed(midiKey + currentOctave * 12, 127);
        }
        // wxcvbn.. => piano
        else if (event.nativeScanCode >= 52 && event.nativeScanCode < 62) {
            let midiKey = _scancodeToMidiKey(event.nativeScanCode);
            if (midiKey != -1)
                notePressed(midiKey + currentOctave * 12, 127);
        }
        else if (event.text == ">") {
            octaveUp();
            currentOctave += 1;
        }
        else if (event.text == "<") {
            octaveDown();
            if (currentOctave > 0)
                currentOctave -= 1;
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
        if (event.key == Qt.Key_Shift) {
            shiftReleased();
            isShiftPressed = false;
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
        else if (!_pianoSelected && (event.nativeScanCode >= 38 && event.nativeScanCode < 46)) {
            let padNumber = event.nativeScanCode - 38;
            if (event.modifiers & Qt.ControlModifier) {
                padReleased(padNumber + 8);
            }
            else {
                padReleased(padNumber);
            }
        }
        else if (_pianoSelected && (event.nativeScanCode >= 38 && event.nativeScanCode < 50)) {
            let midiKey = _scancodeToMidiKey(event.nativeScanCode);
            if (midiKey != -1)
                noteReleased(midiKey + currentOctave * 12, 127);
        }
        // wxcvbn.. => piano
        else if (event.nativeScanCode >= 52 && event.nativeScanCode < 62) {
            let midiKey = _scancodeToMidiKey(event.nativeScanCode);
            if (midiKey != -1)
                noteReleased(midiKey + currentOctave * 12);
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
                22: 15,
                1: 16 // modulation wheel
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
            //console.log("+++ midi received", message);
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
                if (cc == 1) { // modulation wheel
                    let knob = knobs.itemAt(16);
                    root.knobMoved(16, v / 127.0 * (knob.max - knob.min) + knob.min);
                }
                else if ((cc in cc_to_knob) && (v != 0x40)) {
                    const knobNumber = cc_to_knob[cc];
                    let knob = knobs.itemAt(knobNumber);
                    let amount = v - 0x40;
                    if (amount > 0) {
                        //for (var i = 0; i < amount; i++)
                            if (knob.hasValue) {
                                knob.increment(0);
                            } else {
                                if (knob.value < 0) {
                                    knob.value = 0;
                                }
                                knob.value += 1;
                                if (knob.value > 15) {
                                    knob.value = 0;
                                    root.knobIncremented(knobNumber);
                                }
                            }
                        if (knob.hasValue)
                            root.knobMoved(knobNumber, knob.value);
                    }
                    else if (amount < 0) {
                        //for (var i = 0; i < -amount; i++)
                            if (knob.hasValue) {
                                knob.decrement(0);
                            } else {
                                if (knob.value > 0) {
                                    knob.value = 0;
                                }
                                knob.value -= 1;
                                if (knob.value < -15) {
                                    knob.value = 0;
                                    root.knobDecremented(knobNumber);
                                }
                            }
                        if (knob.hasValue)
                            root.knobMoved(knobNumber, knob.value);
                    }
                }
                else if (cc in cc_to_pad) {
                    const padNumber = cc_to_pad[cc];
                    if (v == 0x7F)
                        root.padPressed(padNumber);
                    else
                        root.padReleased(padNumber);
                }
            }
            else if ((message[0] == 0xF0) && message.length > 6) {
                // SYSEX
                let rem = message.slice(6, -1);
                if ((rem[0] == 0x02) && (rem[1] == 0x00) && (rem[2] == 0x00) && (rem[3] == 0x2E)) {
                    if (rem[4] == 0x7F) {
                        root.shiftPressed();
                        root.isShiftPressed = true;
                    }
                    else {
                        root.shiftReleased();
                        root.isShiftPressed = false;
                    }
                }
            }
        }
    }

    // double tap logic
    property var padLastPressedTime: ({})
    onPadPressed : {
        let t = new Date();
        if (padNumber in padLastPressedTime) {
            let msDiff = t - padLastPressedTime[padNumber];
            if (msDiff < doubleTapMaxTimeMs) {
                root.padDoubleTapped(padNumber);
            }
        }
        padLastPressedTime[padNumber] = t;
    }
}
