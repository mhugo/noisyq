import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

import "../../instruments/common" as Common

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
                let qmlFile = "../../instruments/" + instruments[i]["qml"];
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
                Qt.callLater(function() {instrumentStack.loadState(state);});
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
    Board {
        id: board
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

    StackLayout {
        // A layout that stacks a widget for each instrument
        id: instrumentStack
        anchors.top: infoScreen.bottom
        visible: false

        width: parent.width
        height: (main.unitSize+main.legendSize)*2

        function saveState() {
            // save the state of each instrument
            var voiceStates = [];
            for (var voice in voiceInstrument) {
                let instr = voiceInstrument[voice].instrument;
                let instrState = null;
                if (instr.saveState !== undefined) {
                    instrState = instr.saveState();
                }
                voiceStates.push({
                    "voice": voice,
                    "instrument": instrumentComponents[voiceInstrument[voice].index].name,
                    "state": instrState
                });
            }
            return {
                "voices": voiceStates,
                "voiceStackLayoutIndex": voiceStackLayoutIndex
            };
        }

        function loadState(state) {
            //
            console.log("loadState");
            voiceStackLayoutIndex = state["voiceStackLayoutIndex"];

            let voiceStates = state["voices"];
            for (var i = 0; i < voiceStates.length; i++) {
                let obj = instrumentStack.assignInstrument(voiceStates[i].instrument, voiceStates[i].voice);
                if (obj) {
                    obj.loadState(voiceStates[i].state);
                }
            }            
            voiceKnob.updateInstrKnob();
        }

        // Instrument associated to each voice
        // Key: a voice number (int converted to string by JS)
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

            // FIXME install a saveState function if none
            if (obj.saveState === undefined) {
            }
            if (obj.loadState === undefined) {
            }

            if (obj != null) {
                children.push(obj);
                voiceInstrument[voiceNumber] = {"instrument": obj, "index": instrumentIndex};
                voiceStackLayoutIndex[voiceNumber] = children.length - 1;
            }
            return obj;
        }

        // Assign a given Item to the current instrument slot
        function assignInstrument(name, voice) {
            // look for the instrument in the component list
            let obj = null;
            for (var i in instrumentComponents) {
                if (instrumentComponents[i].name == name) {
                    return assignInstrumentFromIndex(i, voice);
                }
            }
            console.log("!!! Cannot find instrument", name);
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
            enabled: instrumentStack.visible
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

    Connections {
        target: board
        onPadPressed : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = Pad.Color.Red;
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

            Component.onCompleted: {
                infoScreen.text = enumValues[~~value];
            }
        }

        Common.PlacedDial {
            id: voiceKnob
            isInteger: true
            knobNumber: 8

            min: 0
            max: 15
            legend: "Voice"

            function updateInstrKnob() {
                if (modeStackLayout.currentIndex == 0) { // instrument assign
                    let instr = instrumentStack.instrumentAt(~~value);
                    if (instr) {
                        chooseInstrKnob.value = parseInt(instr.index) + 1;
                    }
                    else {
                        chooseInstrKnob.value = 0;
                    }
                }
            }

            onValueChanged: {
                updateInstrKnob();
            }
        }

        StackLayout {
            id: modeStackLayout

            currentIndex: ~~modeKnob.value

            /////////////////////////////
            //
            //     Instrument assign
            //
            /////////////////////////////
            Item {
                Common.PlacedDial {
                    id: chooseInstrKnob
                    knobNumber: 9
                    legend: "Instr. type "

                    enumValues: ["None"]

                    Component.onCompleted: {
                        for (var i = 0; i < instrumentComponents.length; i++) {
                            enumValues.push(instrumentComponents[i].name);
                        }
                        max = enumValues.length - 1;
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
                    enabled: modeStackLayout.currentIndex == 0
                }
            }

            ////////////////////////
            //
            //      Sequencer
            //
            ////////////////////////
            Item {
                id: sequencerDisplay

                property int step: 0
                property string oldColor: Pad.Color.Black
                property int oldStep: -1

                function lightStep(step) {
                    if (oldStep > -1)
                        padRep.itemAt(oldStep % 16).color = oldColor;
                    oldColor = padRep.itemAt(step % 16).color;
                    padRep.itemAt(step % 16).color = Pad.Color.Red;
                    oldStep = step;
                }

                Common.PlacedKnobMapping {
                    id: bpm
                    mapping.knobNumber: 1
                    mapping.isInteger: true
                    mapping.min: 20
                    mapping.max: 300
                    mapping.value: 120
                    Common.NumberFrame {
                        value: parent.value
                        displaySign: false
                        text: "BPM"
                    }
                }
                
                Item {
                    // all pads
                    y: (main.unitSize+main.legendSize) * 2
                }

                Item {
                    // icons above piano keys
                    id: pianoIcons
                    y: main.unitSize*4 + main.legendSize*2 + 8
                    readonly property real keyWidth: (main.width - piano.octaveWidth) / 15
                    property bool isPlaying: false
                    Image {
                        source: "pause.svg"
                        width: 16
                        height: 16
                        x: (parent.keyWidth - width) / 2
                        visible: parent.isPlaying
                    }
                    Image {
                        source: "play.svg"
                        width: 16
                        height: 16
                        x: (parent.keyWidth - width) / 2
                        visible: !parent.isPlaying
                    }
                    Image {
                        source: "stop.svg"
                        width: 16
                        height: 16
                        x: (parent.keyWidth - width) / 2 + parent.keyWidth
                    }
                }

                Connections {
                    target: board
                    onNoteReleased: {
                        if (board.isShiftPressed) {
                            if (note % 12 == 0) {
                                // First note : play/pause
                                sequencer.toggle_play_pause(bpm.value);
                            }
                            if (note % 12 == 2) {
                                // Second note : stop
                                sequencer.stop();
                                step = 0;
                            }
                        }
                    }
                    enabled: sequencerDisplay.visible
                }
                Connections {
                    target: sequencer
                    onStateChanged: {
                        pianoIcons.isPlaying = sequencer.is_playing();
                    }
                    onStep: {
                        sequencerDisplay.lightStep(step);
                    }
                }

                function _updateSteps() {
                    // Change step colors based on steps from the sequencer
                    let currentVoice = ~~voiceKnob.value;
                    for (var p = 0; p < 16; p++) {
                        padRep.itemAt(p).color = Pad.Color.Black;
                    }
                    let events = sequencer.list_events(0, 1, 4, 1);
                    for (var i = 0; i < events.length; i++) {
                        let event = events[i];
                        if (event.channel != currentVoice)
                            continue;
                        // round the event start time to the previous step
                        let event_time = event.time_amount / event.time_unit;
                        let step_number = ~~(event_time * 4);
                        console.log(event.time_amount, event.time_unit, "event_time", event_time, "step_number", step_number);
                        if (step_number < 16)
                            Qt.callLater(function(){padRep.itemAt(step_number).color = Pad.Color.Blue});
                    }
                }

                onVisibleChanged: {
                    if (visible) {
                        _updateSteps();
                    }
                }

                Connections {
                    target: voiceKnob
                    onValueChanged: {
                        sequencerDisplay._updateSteps();
                    }
                    enabled: sequencerDisplay.visible
                }
                Connections {
                    target: board
                    onPadReleased: {
                        let currentVoice = ~~voiceKnob.value;
                        // toggle step
                        let l = sequencer.list_events(
                            padNumber, 4,
                            padNumber, 4);
                        if (l.length) {
                            for (var i = 0; i < l.length; i++) {
                                if (l[i].channel == currentVoice) {
                                    console.log("Event", l[i].time_amount, l[i].time_unit, l[i].event.note);
                                    sequencer.remove_event(l[i].channel,
                                                           l[i].time_amount,
                                                           l[i].time_unit,
                                                           l[i].event);
                                }
                            }
                        }
                        else {
                            // add an event
                            sequencer.add_event(currentVoice,
                                                padNumber,
                                                4,
                                                {
                                                    "event_type": "note_event",
                                                    "note": 60,
                                                    "velocity": 100,
                                                    "duration_amount": 1,
                                                    "duration_unit": 4
                                                });
                        }
                        sequencerDisplay._updateSteps();
                    }
                }
            }

            ///////////////////////////////
            //
            //       Instrument Edit
            //
            ///////////////////////////////
            Item {
                Connections {
                    target: board
                    onPadReleased : {
                        if (padNumber == board.knob9SwitchId) {
                            // click => edit instrument
                            instrumentStack.editInstrument(~~voiceKnob.value);
                        }
                    }
                    enabled: modeStackLayout.currentIndex == 2
                }
            }
        }
    }

    Connections {
        target: sequencer
        onNoteOn: {
            let instr = instrumentStack.instrumentAt(channel);
            if (instr != null) {
                lv2Host.noteOn(instr.instrument.lv2Id, note, velocity);
            }
        }
        onNoteOff: {
            let instr = instrumentStack.instrumentAt(channel);
            if (instr != null) {
                lv2Host.noteOff(instr.instrument.lv2Id, note);
            }
        }
    }
}
