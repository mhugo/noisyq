import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

// TODO
// - remap keyboard:
//   - add shift button => shift
//   - add "pad 1-8/9-16" button => capslock
//   - add slider
//   - add pitch bend


ColumnLayout {
    id: main

    readonly property int unitSize: 120

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

        let state = JSON.parse(Utils.readFile("state.json"));
        if (state) {
            console.log("-- Loading state from state.json --");


            canvas.loadState(state);
        }
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

                    function increment() {
                        value = value + (isInteger ? 1 : (max - min) / 50.0);
                        if (value > max) {
                            value = max;
                        }
                    }
                    function decrement() {
                        value = value - (isInteger ? 1 : (max - min) / 50.0);
                        if (value < min) {
                            value = min;
                        }
                    }
                }
            }

            Repeater {
                id: pads
                model: 8
                Item {
                    property string color: "white"
                }
            }

            readonly property int knob1SwitchId : 16
            readonly property int knob9SwitchId : 17

            function knobValue(knobNumber) {
                return knobs.itemAt(knobNumber).value;
            }

            function setKnobValue(knobNumber, value) {
                knobs.itemAt(knobNumber).value = value;
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
                if (event.key == Qt.Key_Up) {
                    knobs.itemAt(selectedKnob).increment();
                    knobMoved(selectedKnob, knobs.itemAt(selectedKnob).value);
                }
                if (event.key == Qt.Key_Down) {
                    knobs.itemAt(selectedKnob).decrement();
                    knobMoved(selectedKnob, knobs.itemAt(selectedKnob).value);
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
                    padPressed(padNumber);
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
                    padReleased(padNumber);
                }
                else if (event.nativeScanCode >= 52 && event.nativeScanCode < 62) {
                    let key = event.nativeScanCode - 52 + 60;
                    noteReleased(key);
                }
            }

            // transfer all signals coming from the gear
            Connections {
                target: gear
                onPadPressed : board.padPressed(padNumber)
                onPadReleased: board.padReleased(padNumber)
                onKnobMoved: {
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
                onNotePressed: board.notePressed(note, velocity)
                onNoteReleased: board.noteReleased(note)
                onOctaveUp: board.octaveUp()
                onOctaveDown: board.octaveDown()
            }
        }
    }

    Rectangle {
        id: infoScreen
        color: "#444444"
        width: parent.width
        height: 40

        property alias text: text.text

        Text {
            id: text
            anchors.fill: infoScreen
            font.family: pixelFont.name
            font.pointSize: 8
            color: "white"
            text: "Display"
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
        Text {
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

    RowLayout {
        id: padMenu
        property alias texts: padRep.model

        // update one particular pad text
        function updateText(padNumber, newText) {
            texts = texts.slice(0, padNumber).concat([newText].concat(texts.slice(padNumber+1)));            
        }

        spacing: 0
        Repeater {
            id: padRep
            model: ["", "", "", "", "", "", "", ""]
            Pad {
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
                }
            }
        }
    }

    RowLayout {
        id: piano
        property int octave: 4
        Text {
            id: octaveText
            text: "Octave\n" + parent.octave
            horizontalAlignment: Text.AlignHCenter
        }
        Item {
            id: pianoK
            width: main.width
            height: main.unitSize*1.5
            property real keyWidth: (main.width - octaveText.width) / 15

            // note index -> corresponding Rectangle for key
            property var keyForNote: ({})

            // 
            function noteOn(note, velocity) {
                keyForNote[note].color = "grey";
            }
            function noteOff(note) {
                keyForNote[note].color = keyForNote[note].initialColor;
            }

            Repeater {
                id: whiteKeyRep
                model: 15
                property var semis : [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24]
                Rectangle {
                    x: (index * pianoK.keyWidth)
                    y: parent.y
                    width: pianoK.keyWidth
                    height: parent.height
                    border.width: 1
                    Layout.margins: 0
                    border.color: "black"
                    property string initialColor: "white"
                    color: initialColor
                }
            }
            Repeater {
                id: blackKeyRep
                model: [0, 1, 3, 4, 5, 7, 8, 10, 11, 12]
                property var semis : [1, 3, 6, 8, 10, 13, 15, 18, 20, 22]
                Rectangle {
                    x: ((modelData+0.75) * pianoK.keyWidth)
                    y: parent.y
                    width: pianoK.keyWidth / 2
                    height: parent.height / 2
                    border.width: 1
                    Layout.margins: 0
                    border.color: "black"
                    property string initialColor: "black"
                    color: initialColor
                }
            }

            Component.onCompleted : {
                for (var i = 0; i < whiteKeyRep.semis.length; i++) {
                    keyForNote[whiteKeyRep.semis[i]] = whiteKeyRep.itemAt(i);
                }
                for (var i = 0; i < blackKeyRep.semis.length; i++) {
                    keyForNote[blackKeyRep.semis[i]] = blackKeyRep.itemAt(i);
                }
            }
        }
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
                case 0:
                    state = "projectMenu";
                    break;
                case 1:
                    state = "instrMenu";
                    break;
                case 7:
                    quit();
                    break;
                }
            }
                break;
            case "projectMenu": {
                if (padNumber == 7) {
                    state = "rootMenu";
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
            pianoK.noteOn(note - piano.octave * 12, velocity);
        }

        onNoteReleased : {
            if (state == "instrEditMenu") {
                let cur = canvas.currentInstrumentObject();
                if (cur != null) {
                    lv2Host.noteOff(cur.lv2Id, note);
                }
            }
            pianoK.noteOff(note - piano.octave * 12);
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
                texts: ["Project", "Instr.", "", "", "", "", "", "Quit"]
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
            name: "projectMenu"
            PropertyChanges {
                target: padMenu
                texts: ["", "", "", "", "", "", "", "Back"]
            }
            PropertyChanges {
                target: infoScreen
                text: "Project"
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
