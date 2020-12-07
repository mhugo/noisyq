import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

import "instruments/common" as Common

Item {
    id: main

    readonly property int unitSize: 120

    readonly property int legendSize: 0.3 * unitSize

    width: unitSize*8
    height: childrenRect.height

    function quit()
    {
        Utils.saveFile("state.json", JSON.stringify(instrumentStack.saveState()));
        Qt.callLater(Qt.quit);
    }

    // List of {"name": "xxx", "lv2Url": "xxx", "component": Component}
    property var instrumentComponents : []

    Component.onCompleted: {
        // TODO load stub for lv2Host if run from qmlscene
        // use JS Object.defineProperty to add it to the "root" object ?
        console.log("____qt", Qt.application.displayName);
        // load instruments
        let instruments = JSON.parse(Utils.readFile("instruments/instruments.json"));
        if (instruments) {
            for (var i in instruments) {
                let qmlFile = "instruments/" + instruments[i]["qml"];
                let comp = Qt.createComponent(qmlFile);
                if (comp.status == Component.Ready) {
                    let url = instruments[i]["url"];
                    console.log("== Loading component for LV2 " + url + " from " + qmlFile);
                    instrumentComponents.push({
                        "name": instruments[i]["name"],
                        "lv2Url": instruments[i]["url"],
                        "component": comp
                    });
                }
                else if (comp.status == Component.Error) {
                    console.log("## Error loading " + qmlFile);
                    console.log(comp.errorString());
                }
            }
        }

        let stateStr = Utils.readFile("state.json");
        if (stateStr) {
            let state = JSON.parse(stateStr);
            if (state) {
                console.log("-- Loading state from state.json --");
                instrumentStack.loadState(state);
            }
        }

        //console.log("midi receive", midi.receive_message());
    }

    FontLoader {
        id: titleFont
        source: "fonts/big_noodle_titling.ttf"
    }
    FontLoader {
        id: pixelFont
        source: "fonts/Pixeled.ttf"
    }
    FontLoader {
        id: monoFont
        //source: "fonts/MoonGlossDisplayThin.ttf"
        source: "fonts/Oxanium-Regular.ttf"
    }

    // Simulate knobs and pads activations
    Text {
        id: board

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
                    board.notePressed(message[1], message[2]);
                }
                else if ((message[0] & 0xF0) == 0x80) {
                    // NOTE_OFF
                    board.noteReleased(message[1]);
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
                            board.knobMoved(knobNumber, knobs.itemAt(knobNumber).value);
                        }
                        else if (amount < 0) {
                            for (var i = 0; i < -amount; i++)
                                knobs.itemAt(knobNumber).decrement();
                            board.knobMoved(knobNumber, knobs.itemAt(knobNumber).value);
                        }
                    }
                    if (cc in cc_to_pad) {
                        const padNumber = cc_to_pad[cc];
                        if (v == 0x7F)
                            board.padPressed(padNumber);
                        else
                            board.padReleased(padNumber);
                    }
                }
                // TODO SYSEX
            }
        }
    }

    Rectangle {
        id: infoScreen
        color: "#444444"
        width: parent.width
        height: 40

        anchors.top: board.bottom

        property alias text: text.text

        function flash(msg) {
            // display a message for some time, then disappear

            if (! flashTimer.running)
                _textBackup = text.text;
            text.text = msg;
            flashTimer.restart();
            
        }
        property string _textBackup : ""
        Timer {
            id: flashTimer
            interval: 1000
            onTriggered: {
                parent.text = parent._textBackup;
            }
        }

        Text {
            id: text
            anchors.fill: infoScreen
            font.family: titleFont.name
            font.pointSize: 14
            color: "white"
            text: ""
            verticalAlignment: Text.AlignVCenter
        }
    }

    Item {
        id: mainLayout
        anchors.top: infoScreen.bottom
        Common.PlacedDial {
            id: modeKnob
            knobNumber: 0

            enumValues: [
                "Instr. assign",
                "Sequencer",
                "Instr. edit"
            ]

            legend: "Function"

            onValueChanged: {
                modeStackLayout.currentIndex = ~~value;
            }
        }

        Common.PlacedDial {
            id: voiceKnob
            isInteger: true
            knobNumber: 8

            min: 0
            max: 15
            legend: "Voice"

            onValueChanged: {
                if (modeStackLayout.currentIndex == 0) { // instrument assign
                    let instr = instrumentStack.instrumentAt(~~value);
                    if (instr) {
                        chooseInstrKnob.value = instr.index + 1;
                    }
                    else {
                        chooseInstrKnob.value = 0;
                    }
                }
            }
        }

        StackLayout {
            id: modeStackLayout

            // Instrument assign
            Item {
                Common.PlacedDial {
                    id: chooseInstrKnob
                    knobNumber: 9
                    legend: "Instr. type "

                    enumValues: ["None"]

                    Component.onCompleted: {
                        max = instrumentComponents.length;
                        for (var i = 0; i < instrumentComponents.length; i++) {
                            enumValues.push(instrumentComponents[i].name);
                        }
                        _initIfVisible();
                    }
                }

                Connections {
                    target: board
                    onPadReleased : {
                        if (padNumber == board.knob9SwitchId) {
                            // click => assign instrument to voice
                            let instrumentIndex = ~~chooseInstrKnob.value - 1;
                            if (instrumentIndex == -1) {
                                // unassign
                                // TODO
                            }
                            else {
                                instrumentStack.assignInstrumentFromIndex(instrumentIndex, ~~voiceKnob.value);
                            }
                        }
                    }
                    enabled: visible
                }
            }

            // Trigger
            Item {}

            // Instrument Edit
            Item {
                Connections {
                    target: board
                    onPadReleased : {
                        if (padNumber == board.knob9SwitchId) {
                            // click => edit instrument
                            instrumentStack.editInstrument(~~voiceEditKnob.value);
                        }
                    }
                    enabled: visible
                }
            }
        }
    }

    StackLayout {
        // A layout that stacks a widget for each instrument
        id: instrumentStack
        anchors.top: infoScreen.bottom
        visible: false

        width: parent.width
        height: main.unitSize*3

        function saveState() {
            /*
            // save the state of each instrument
            var instrStates = []
            for (var i = 0; i < instruments.length; i++) {
                if (instruments[i]) {
                    let state = instruments[i].saveState();
                    instrStates.push({
                        "name": instruments[i].name,
                        "state": state
                    });
                }
                else {
                    instrStates.push(null);
                }
            }
            return {
                "instruments": instrStates,
                "stackMapping": instrumentStackIndex
            };
            */
        }

        function loadState(state) {
            /*
            //
            instrumentStackIndex = state["stackMapping"];

            // invert the mapping instrument -> stack index
            // to get a mapping stack index -> instrument
            let stackInstrumentIndex = {};
            for (var instr in instrumentStackIndex) {
                let idx = instrumentStackIndex[instr];
                stackInstrumentIndex[idx] = instr;
            }

            for (var i in stackInstrumentIndex) {
                currentInstrument = stackInstrumentIndex[i];
                let instrState = state["instruments"][currentInstrument];
                if (instrState) {
                    let obj = assignInstrument(instrState["name"]);
                    obj.loadState(instrState["state"]);
                }
            }
            */
        }

        // Instrument associated to each voice
        // Each instrument object is a {"instrument": instrument, "index": index in instrumentComponents}
        property var voiceInstrument : ({})

        // map of voice number -> stack layout index
        property var voiceStackLayoutIndex : ({})

        property int _currentVoice : 0

        function editInstrument(voiceNumber) {
            // display the component associated with the current voice in the instrumentStack
            if (voiceInstrument[voiceNumber] !== undefined) {
                currentIndex = voiceStackLayoutIndex[voiceNumber];
                mainLayout.visible = false;
                instrumentStack.visible = true;
                _currentVoice = voiceNumber;
            }
        }

        function currentInstrumentObject() {
            if (voiceInstrument[_currentVoice])
                return voiceInstrument[_currentVoice].instrument;
            return undefined;
        }

        function endEditInstrument() {
            console.log("** end edit instrument");
            instrumentStack.visible = false;
            mainLayout.visible = true;
        }

        function instrumentAt(voiceNumber) {
            return voiceInstrument[voiceNumber];
        }

        function assignInstrumentFromIndex(instrumentIndex, voiceNumber) {
            let obj = instrumentComponents[instrumentIndex].component.createObject(main, {"visible": false});
            let lv2Id = lv2Host.addInstance(instrumentComponents[instrumentIndex].lv2Url);
            obj.lv2Id = lv2Id;
            obj.unitSize = main.unitSize;
            obj.init();
            if (obj.quit !== undefined) {
                obj.quit.connect(instrumentStack.endEditInstrument);
            }
            console.log("lv2id", obj.lv2Id);

            if (obj != null) {
                children.push(obj);
                voiceInstrument[voiceNumber] = {"instrument": obj, "index": instrumentIndex};
                voiceStackLayoutIndex[voiceNumber] = children.length - 1;
            }
            return obj;
        }

        // Assign a given Item to the current instrument slot
        function assignInstrument(name) {
            // look for the instrument in the component list
            let obj = null;
            for (var i in instrumentComponents) {
                if (instrumentComponents[i].name == name) {
                    return assignInstrumentFromIndex(i, currentVoice);
                }
            }
            console.log("Cannot find instrument", name);
        }

        function removeInstrumentAt(voiceNumber) {
            delete voiceInstrument[voiceNumber];
            delete voiceStackLayoutIndex[voiceNumber];
        }

        Connections {
            target: board
            onPadPressed: {
                // call padPressed() function of instrument
                let cur = instrumentStack.currentInstrumentObject();
                if (cur != null && cur.padPressed !== undefined) {
                    cur.padPressed(padNumber);
                }
            }
            onPadReleased: {
                // call padReleased() function of instrument
                let cur = instrumentStack.currentInstrumentObject();
                if (cur != null && cur.padReleased !== undefined) {
                    cur.padReleased(padNumber);
                }
            }
            onKnobMoved: {
                // call knobMoved() function of instrument
                let cur = instrumentStack.currentInstrumentObject();
                if (cur != null && cur.knobMoved !== undefined) {
                    cur.knobMoved(knobNumber, amount);
                }
            }
            onNotePressed: {
                let cur = instrumentStack.currentInstrumentObject();
                if (cur != null) {
                    lv2Host.noteOn(cur.lv2Id, note, velocity);
                }
            }
            onNoteReleased : {
                let cur = instrumentStack.currentInstrumentObject();
                if (cur != null) {
                    lv2Host.noteOff(cur.lv2Id, note);
                }
            }
            enabled: visible
        }

        // index: 0 - blank with optional text
        Text {
            id: textPanel
            width: unitSize
            height: unitSize
        }
    }

    Item {
        id: padMenu
        property alias texts: padRep.model
        anchors.top: instrumentStack.bottom

        implicitWidth: 8 * unitSize
        implicitHeight: 2 * unitSize
        x: 0
        y: 0

        // update one particular pad text
        function updateText(padNumber, newText) {
            texts = texts.slice(0, padNumber).concat([newText].concat(texts.slice(padNumber+1)));            
        }

        function clear() {
            texts = ["", "", "", "", "", "", "", "",
                     "", "", "", "", "", "", "", ""];
        }

        property var _saveStack : []
        function pushState() {
            _saveStack.push(texts);
        }

        function popState() {
            let t = _saveStack.pop();
            for (var i = 0; i < t.length; i++) {
                console.log("pop", t[i]);
            }
            texts = t;
        }

        //spacing: 0
        Repeater {
            id: padRep
            model: ["", "", "", "", "", "", "", "",
                    "", "", "", "", "", "", "", ""]
            Pad {
                x: (index % 8) * unitSize
                y: ~~(index / 8) * unitSize
                color: board.padColor(index)
                size: main.unitSize
                Text {
                    width: parent.width
                    height: parent.height
                    text: modelData
                    font.family: titleFont.name
                    font.pointSize: 14
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    visible: ! modelData.startsWith(":")
                }
                Image {
                    source: "white_menu.svg"
                    width: parent.width
                    height: parent.height
                    visible: modelData == ":menu:"
                }
            }
        }
    }

    Piano25Keys {
        id: piano
        anchors.top: padMenu.bottom
    }

    state: "instrAssign"

    Connections {
        target: board
        onPadPressed : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = "red";
        }
        onPadReleased : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = board.padColor(padNumber);
        }

        onNotePressed : {
            piano.noteOn(note - piano.octave * 12, velocity);
        }

        onNoteReleased : {
            piano.noteOff(note - piano.octave * 12);
        }

        onOctaveUp : {
            piano.octave += 1;
        }
        onOctaveDown : {
            piano.octave -= 1;
            if (piano.octave < 0)
                piano.octave = 0;
        }
    }

    states : [
        State {
            name: "instrEditChoose"
            PropertyChanges {
                target: infoScreen
                text: "Instrument edit"
            }
            PropertyChanges {
                target: chooseInstrKnob
                visible: false
            }
        },
        State {
            name: "trigger"
            PropertyChanges {
                target: chooseInstrKnob
                visible: false
            }
        },
        State {
            name: "instrAssign"
            PropertyChanges {
                target: infoScreen
                text: "Instrument assign"
            }
            PropertyChanges {
                target: chooseInstrKnob
                visible: true
            }
        }
    ]
}
