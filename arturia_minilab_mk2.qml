import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

import "instruments/common" as Common

// TODO
// - remap keyboard:
//   - add shift button => shift
//   - add "pad 1-8/9-16" button => capslock
//   - add slider
//   - add pitch bend


ColumnLayout {
    id: main

    readonly property int unitSize: 120

    readonly property int legendSize: 0.3 * unitSize

    width: unitSize*8

    function quit()
    {
        Utils.saveFile("state.json", JSON.stringify(canvas.saveState()));
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
                canvas.loadState(state);
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
    RowLayout {
        // simulate knobs and pads activations
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
    }

    Rectangle {
        id: infoScreen
        color: "#444444"
        width: parent.width
        height: 40

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

    StackLayout {
        id: canvas
        width: parent.width
        height: main.unitSize*3

        function saveState() {
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
        }

        function loadState(state) {
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
        }

        // Items associated to each instrument
        property var instruments : [null, null, null, null, null, null, null]

        property int currentInstrument: 0

        // map of instrument number -> stack layout index
        property var instrumentStackIndex : ({})

        function editInstrument() {
            // display the component associated with the instrument in the canvas
            if (instruments[currentInstrument] === null) {
                // blank instrument
                currentIndex = 1;
            }
            else {
                currentIndex = instrumentStackIndex[currentInstrument];
            }
        }

        function endEditInstrument() {
            console.log("** end edit instrument");
            main.state = "instrMenu";
            canvas.currentIndex = 0;
        }

        function currentInstrumentObject() {
            return instruments[currentInstrument];
        }

        // Assign a given Item to the current instrument slot
        function assignInstrument(name) {
            // look for the instrument in the component list
            let obj = null;
            for (var i in instrumentComponents) {
                if (instrumentComponents[i].name == name) {
                    obj = instrumentComponents[i].component.createObject(main, {});
                    let lv2Id = lv2Host.addInstance(instrumentComponents[i].lv2Url);
                    obj.lv2Id = lv2Id;
                    obj.unitSize = main.unitSize;
                    obj.init();
                    console.log("lv2id", obj.lv2Id);
                    break;
                }
            }
            if (obj != null) {
                children.push(obj);
                instruments[currentInstrument] = obj;
                instrumentStackIndex[currentInstrument] = children.length - 1;
            }
            else {
                console.log("Cannot find instrument", name);
            }
            return obj;
        }

        // index: 0 - blank
        Item {
            width: unitSize
            height: unitSize
            Common.PlacedKnobMapping {
                id: k1
                mapping.isInteger: true
                mapping.knobNumber: 0
                readonly property var functionName: [
                    "Trigger",
                    "Intr. edit"
                ]

                mapping.min: 0
                mapping.max: functionName.length-1
                mapping.parameterDisplay: "Function"
                legend: "Function"

                Dial {
                    x: 0
                    y: 0
                    width: unitSize
                    height: unitSize
                    value: parent.value
                    Text{
                        x: (unitSize - width) / 2
                        y: (unitSize - height) / 2
                        text: k1.functionName[~~parent.value]
                    }
                }
            }
        }

        // index: 1 - no instrument assigned
        ColumnLayout {
            id: blankTrack
            Text {
                text: "No instrument assigned"
            }
            ComboBox {
                id: instrCombo
                Component.onCompleted : {
                    model = instrumentComponents.map(function(x) { return x["name"]; });
                }
            }
            // FIXME
            // knob values must be independant and then saved for each panel
            Connections {
                target: board

                // only visible panels should react to knob / pad changes
                enabled: blankTrack.visible

                onKnobMoved : {
                    if (knobNumber == 0) {
                        instrCombo.currentIndex = ~~amount;
                    }
                }

                onPadPressed : {
                    if (padNumber == 0) {
                        // confirm assignment
                        canvas.assignInstrument(instrCombo.currentText);
                        canvas.currentIndex = canvas.children.length - 1;
                    }
                }
            }

            onVisibleChanged : {
                if (visible) {
                    padMenu.texts = ["Assign"].concat(padMenu.texts.slice(1));
                    board.setKnobIsInteger(0, true);
                    board.setKnobMinMax(0, 0, instrCombo.count-1);
                }
            }
        }
    }

    Item {
        id: padMenu
        property alias texts: padRep.model

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
    }

    state: "rootMenu"

    Connections {
        target: board
        onPadPressed : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = "red";
            if (state == "instrEditMenu") {
                // forward signals to instrument
                let cur = canvas.currentInstrumentObject();
                if (cur != null && cur.padPressed !== undefined) {
                    cur.padPressed(padNumber);
                }
            }
        }
        onPadReleased : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = board.padColor(padNumber);
            switch (state) {
            case "rootMenu": {
                switch (padNumber) {
                case 1:
                    state = "instrMenu";
                    break;
                case 7:
                    quit();
                    break;
                }
            }
                break;
            case "instrMenu": {
                if (padNumber == 7) {
                    state = "rootMenu";
                }
                else {
                    state = "instrEditMenu";
                    canvas.currentInstrument = padNumber;
                    canvas.editInstrument();
                }
            }
                break;
            case "instrEditMenu": {
                // forward signals to instrument
                let cur = canvas.currentInstrumentObject();
                if (cur != null && cur.padReleased !== undefined) {
                    cur.padReleased(padNumber);
                }
            }
                break;
            }
        }

        onNotePressed : {
            if (state == "instrEditMenu") {
                let cur = canvas.currentInstrumentObject();
                if (cur != null) {
                    lv2Host.noteOn(cur.lv2Id, note, velocity);
                }
            }
            piano.noteOn(note - piano.octave * 12, velocity);
        }

        onNoteReleased : {
            if (state == "instrEditMenu") {
                let cur = canvas.currentInstrumentObject();
                if (cur != null) {
                    lv2Host.noteOff(cur.lv2Id, note);
                }
            }
            piano.noteOff(note - piano.octave * 12);
        }

        onKnobMoved : {
            if (state == "instrEditMenu") {
                // forward signals to instrument
                let cur = canvas.currentInstrumentObject();
                if (cur != null && cur.knobMoved !== undefined) {
                    cur.knobMoved(knobNumber, amount);
                }
            }
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
            name: "rootMenu"
            PropertyChanges {
                target: padMenu
                texts: ["", "Instr.", "", "", "", "", "", "Quit",
                       "", "", "", "", "", "", "", ""]
            }
            PropertyChanges {
                target: canvas
                currentIndex: 0
            }
            PropertyChanges {
                target: infoScreen
                text: "Main menu"
            }
        },
        State {
            name: "instrMenu"
            PropertyChanges {
                target: padMenu
                texts: {
                    let newPadMenu = [];
                    for (var i=0; i < 7; i++) {
                        board.setPadColor(i, canvas.instruments[i] ? "green" : "white");
                        if (canvas.instruments[i]) {
                            newPadMenu.push("<" + i.toString() + ">\n" + canvas.instruments[i].name);
                        }
                        else {
                            newPadMenu.push("<" + i.toString() + ">");
                        }
                    }
                    newPadMenu.push("Back");
                    newPadMenu.push("", "", "", "", "", "", "", "");
                    return newPadMenu;
                }
            }
            PropertyChanges {
                target: infoScreen
                text: "Instrument"
            }
        }
    ]
}
