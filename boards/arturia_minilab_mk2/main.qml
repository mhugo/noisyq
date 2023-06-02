import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

import "../../instruments/common" as Common

Item {
    id: main

    readonly property int unitSize: 100

    readonly property int legendSize: 0.3 * unitSize

    width: unitSize*9
    height: childrenRect.height

    function quit()
    {
        let saveState = {
            "voices": instrumentStack.saveState(),
            "sequencer": sequencerDisplay.saveState()
        };
        Utils.saveFile("state.json", JSON.stringify(saveState));
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
        console.log("** instruments **", instrumentComponents.length);

        let stateStr = Utils.readFile("state.json");
        if (stateStr) {
            let state = JSON.parse(stateStr);
            if (state) {
                console.log("-- Loading state from state.json --");
                Qt.callLater(function() {
                    instrumentStack.loadState(state.voices);
                    sequencerDisplay.loadState(state.sequencer);
                });
            }
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
    FontLoader {
        id: musicFont
        source: "fonts/NotoMusic-Regular.ttf"
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
        z: 1
        x: unitSize
        anchors.top: infoScreen.bottom
        visible: instrumentEdit.visible

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
            voiceKnob.updateInstrType();
        }

        // Instrument associated to each voice
        // Key: a voice number (int converted to string by JS)
        // Each instrument object is a {"instrument": instrument, "index": index in instrumentComponents}
        property var voiceInstrument : ({})

        // map of voice number -> stack layout index
        property var voiceStackLayoutIndex : ({})

        property int _currentVoice : 0

        function currentInstrumentObject() {
            if (voiceInstrument[_currentVoice])
                return voiceInstrument[_currentVoice].instrument;
            return undefined;
        }

        function instrumentAt(voiceNumber) {
            return voiceInstrument[voiceNumber];
        }

        function editInstrument(voiceNumber) {
            // display the component associated with the current voice in the instrumentStack
            if (voiceInstrument[voiceNumber] !== undefined) {
                currentIndex = voiceStackLayoutIndex[voiceNumber];
                _currentVoice = voiceNumber;
            }
            else {
                currentIndex = 0;
            }
        }

        function assignInstrumentFromIndex(instrumentIndex, voiceNumber) {
            let obj = instrumentComponents[instrumentIndex].component.createObject(main, {"visible": false});
            let lv2Id = lv2Host.addInstance(instrumentComponents[instrumentIndex].lv2Url);
            obj.lv2Id = lv2Id;
            obj.name = instrumentComponents[instrumentIndex].name;
            obj.unitSize = main.unitSize;
            obj.init();
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
            enabled: instrumentStack.visible
        }

        // index: 0 - blank panel
        Item {
            id: noInstrument
            implicitWidth: unitSize * 8
            implicitHeight: unitSize * 2 + legendSize * 2
            Rectangle {
                color: "#ccc"
                width: unitSize * 7
                height: unitSize + legendSize
            }
            Rectangle {
                color: "#ccc"
                x: unitSize
                y: unitSize + legendSize
                width: unitSize * 7
                height: unitSize + legendSize
            }
        }
    }

    Item {
        id: padMenu
        property alias texts: padRep.model
        anchors.top: instrumentStack.bottom
        x: unitSize

        implicitWidth: 8 * unitSize
        implicitHeight: 4 * unitSize

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
        x: unitSize
    }

    Connections {
        target: board
        onPadPressed : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = Board.Color.Red;
        }
        onPadReleased : {
            if (padNumber < 16)
                padRep.itemAt(padNumber).color = board.padColor(padNumber);
        }

        onNotePressed : {
            if (!board.isShiftPressed) {
                piano.noteOn(note - piano.octave * 12, velocity);
                let instr = instrumentStack.instrumentAt(~~voiceKnob.value);
                if (instr != null) {
                    lv2Host.noteOn(instr.instrument.lv2Id, note, velocity);
                }
            }
        }

        onNoteReleased : {
            if (!board.isShiftPressed) {
                piano.noteOff(note - piano.octave * 12);
                let instr = instrumentStack.instrumentAt(~~voiceKnob.value);
                if (instr != null) {
                    lv2Host.noteOff(instr.instrument.lv2Id, note);
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

    Item {
        id: mainLayout
        anchors.top: infoScreen.bottom
        x: unitSize
        Common.PlacedDial {
            id: modeKnob
            knobNumber: 7

            enumValues: [
                "Instrument",
                "Sequencer",
                "Mixer"
            ]

            legend: "Function"

            color: "#ffaaaa"

            Component.onCompleted: {
                infoScreen.text = enumValues[~~value];
            }

            visible: !board.isShiftPressed
        }
        Common.PlacedKnobMapping {
            id: voiceKnob
            mapping.isInteger: true
            mapping.knobNumber: 8

            mapping.min: 0
            mapping.max: 15

            legend: "Voice"

            color: "#ffaaaa"

            text: ~~value

            onValueChanged: {
                updateInstrType();
            }

            function updateInstrType() {
                console.log("1 update instr type");
                let instr = instrumentStack.instrumentAt(~~value);
                if (instr) {
                    voiceKnob.legend = instrumentComponents[instr.index].name;
                }
                else {
                    voiceKnob.legend = "None";
                }

                if (instrumentEdit.visible) {
                    instrumentStack.editInstrument(~~value);
                }
            }

            // invisible on mixer panel
            visible: modeKnob.value != 2
        }

        Common.PlacedKnobMapping {
            id: assignKnob
            mapping.isInteger: true
            mapping.knobNumber: 8

            mapping.min: 0
            mapping.max: 15

            property int voice: 0

            legend: "None"

            text: voice

            visible: false

            onVisibleChanged: {
                if (visible) {
                    assignKnob.mapping.max = instrumentComponents.length;
                    updateInstrType();
                }
                assignKnob.mapping._initIfVisible();
            }

            onValueChanged: {
                updateInstrType();
            }

            function updateInstrType() {
                let instr = instrumentComponents[~~value];
                if (instr) {
                    assignKnob.legend = "> " + instr.name;
                }
                else {
                    assignKnob.legend = "> None";
                }
            }
        }

        StackLayout {
            id: modeStackLayout

            currentIndex: ~~modeKnob.value

            /////////////////////////////
            //
            //     Instrument edit
            //
            /////////////////////////////
            Item {
                id: instrumentEdit

                Common.PlacedDial {
                    id: subModeKnob
                    knobNumber: 7

                    enumValues: [
                        "Edit",
                        "Presets",
                    ]
                    legend: "Sub Function"
                    color: "#ffaaaa"

                    onValueChanged: {
                        if (~~value == 0) {
                            instrumentStack.visible = true;
                        }
                        else {
                            instrumentStack.visible = false;
                        }
                    }

                    visible: board.isShiftPressed
                }

                Common.Presets {
                    id: presetsControl
                    visible: ~~subModeKnob.value == 1
                    onVisibleChanged: {
                        if (visible) {
                            let instr = instrumentStack.instrumentAt(~~voiceKnob.value);
                            if (instr) {
                                presetsControl.lv2Id = instr.instrument.lv2Id;
                            }
                        }
                    }
                }

                Connections {
                    target: board
                    onPadReleased : {
                        if (padNumber == board.knob9SwitchId) {
                            // click => assign instrument to voice
                            if (voiceKnob.visible) {
                                voiceKnob.visible = false;
                                assignKnob.voice = ~~voiceKnob.value;
                                assignKnob.visible = true;
                            }
                            // 2nd click => assignment
                            else {
                                let instrIndex = ~~assignKnob.value;
                                if (instrumentComponents[instrIndex] === undefined) {
                                    instrumentStack.removeInstrumentAt(assignKnob.voice);
                                }
                                else {
                                    instrumentStack.assignInstrumentFromIndex(instrIndex, assignKnob.voice);
                                }
                                assignKnob.visible = false;
                                voiceKnob.visible = true;
                                instrumentStack.editInstrument(assignKnob.voice);
                            }
                        }
                    }
                    enabled: instrumentEdit.visible && ~~subModeKnob.value == 0
                }
            }

            ////////////////////////
            //
            //      Sequencer
            //
            ////////////////////////
            Sequencer {
                id: sequencerDisplay
            }

            ////////////////////////
            //
            //      Mixer
            //
            ////////////////////////
            Item {
                id: mixer
                property int voiceSelected: -1
                Common.PlacedKnobMapping {
                    id: volumeKnob
                    legend: "Volume"
                    mapping.isInteger: false
                    mapping.value: 1.0
                    mapping.min: 0.0
                    mapping.max: 1.0
                    mapping.knobNumber: 0
                    visible: false

                    text: (value * 100).toFixed(0)

                    onValueChanged: {
                        if (mixer.voiceSelected != -1) {
                            volumeSliders.itemAt(mixer.voiceSelected).volume = value;
                        }
                    }
                }
                Common.KnobMapping {
                    id: volumeWheel
                    isInteger: false
                    min: 0.0
                    max: 1.0
                    // modulation wheel
                    knobNumber: 16
                    parameterDisplay: "modulation wheel"
                    onValueChanged: {
                        volumeKnob.value = value;
                    }
                }
                Common.PlacedKnobMapping {
                    id: panningKnob
                    legend: "Panning"
                    mapping.isInteger: false
                    mapping.value: 0.0
                    mapping.min: -1.0
                    mapping.max: 1.0
                    mapping.knobNumber: 1
                    visible: false

                    text: value.toFixed(1)

                    onValueChanged: {
                        if (mixer.voiceSelected != -1) {
                            volumeSliders.itemAt(mixer.voiceSelected).panning = value;
                        }
                    }
                }
                Connections {
                    target: board
                    onPadPressed : {
                        if (padNumber < 8) {
                            volumeKnob.visible = true;
                            panningKnob.visible = true;
                            mixer.voiceSelected = padNumber;
                            volumeKnob.value = volumeSliders.itemAt(padNumber).volume;
                            board.setKnobValue(volumeKnob.knobNumber, volumeKnob.value);
                            volumeWheel.value = volumeSliders.itemAt(padNumber).volume;
                            board.setKnobValue(volumeWheel.knobNumber, volumeWheel.value);
                        }
                    }
                    onPadReleased : {
                        if (padNumber < 8) {
                            mixer.voiceSelected = -1;
                            volumeKnob.visible = false;
                            panningKnob.visible = false;
                            // switch voice
                            voiceKnob.value = padNumber;
                        }
                        else if (padNumber == board.knob1SwitchId) {
                            // mute / unmute
                            volumeSliders.itemAt(mixer.voiceSelected).muted = !volumeSliders.itemAt(mixer.voiceSelected).muted;
                        }
                    }
                    enabled: mixer.visible
                }

                Repeater {
                    model: 8
                    Common.PlacedPadText {
                        padNumber: index
                        text: index + 1

                        onVisibleChanged: {
                            if (visible) {
                                let instr = instrumentStack.instrumentAt(index);
                                let muted = (instr === undefined) || lv2Host.getMuted(instr.instrument.lv2Id);
                                let color = muted ? Board.Color.Red : Board.Color.Black;
                                board.setPadColor(index, color);
                                padRep.itemAt(index).color = color;
                            }
                        }
                    }
                }

                Repeater {
                    id: volumeSliders
                    model: 8

                    Item {
                        id: slider

                        property real volume: 0.0
                        property bool muted: true
                        property real panning: 0.0

                        y: 2 * (unitSize + legendSize) + 2 * unitSize

                        Item {
                            // the panning horizontal slider
                            width: 0.9 * unitSize / 2
                            height: 0.9 * legendSize
                            x: unitSize * index + unitSize * 0.30
                            y: 2 * unitSize + legendSize * 0.5

                            Rectangle {
                                width: parent.width
                                height: 3
                                color: "black"
                            }

                            Rectangle {
                                x: parent.parent.panning * parent.width / 2 + parent.width / 2 - width / 2
                                y: -3
                                height: 9
                                width: 6
                                color: "black"
                            }

                        }

                        // the main volume vertical slider
                        Rectangle {
                            width: 0.9 * unitSize / 2
                            height: 1.9 * unitSize
                            x: unitSize * index + unitSize * 0.30
                            y: unitSize * 0.05
                            border.color: parent.muted ? "grey" : "black"
                            border.width: 3
                            radius: unitSize / 10

                            Rectangle {
                                id: handle
                                color: parent.parent.muted ? "grey" : "black"
                                width: 0.32 * unitSize
                                height: 0.1 * unitSize
                                x: (parent.width - width) / 2
                                y: (1.0 - parent.parent.volume) * (parent.height - height*2) + height/2
                                radius: width / 10
                            }

                        }

                        onVisibleChanged: {
                            if (visible) {
                                let instr = instrumentStack.instrumentAt(index);
                                if (instr) {
                                    slider.volume = lv2Host.getVolume(instr.instrument.lv2Id);
                                    slider.muted = lv2Host.getMuted(instr.instrument.lv2Id);
                                    slider.panning = lv2Host.getPanning(instr.instrument.lv2Id);
                                }
                            }
                        }

                        onPanningChanged: {
                            let instr = instrumentStack.instrumentAt(index);
                            if (instr) {
                                lv2Host.setPanning(instr.instrument.lv2Id, panning);
                            }
                        }

                        onVolumeChanged: {
                            let instr = instrumentStack.instrumentAt(index);
                            if (instr) {
                                lv2Host.setVolume(instr.instrument.lv2Id, volume);
                            }
                        }
                        onMutedChanged: {
                            let instr = instrumentStack.instrumentAt(index);
                            if (instr) {
                                lv2Host.setMuted(instr.instrument.lv2Id, muted);
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        // Red rectangles to debug layouting
        id: debugGrid
        anchors.top: infoScreen.bottom
        z: 99
        visible: board.debugEnabled

        Component {
            id: debugRow
            Item {
                Repeater {
                    model: 9
                    Rectangle {
                        x: index * unitSize
                        implicitWidth: main.unitSize
                        implicitHeight: main.unitSize
                        border.color: "red"
                        border.width: 1
                        color: "transparent"
                    }
                }
            }
        }
        
        Component {
            id: debugLegendRow
            Item {
                Repeater {
                    model: 9
                    Rectangle {
                        x: index * unitSize
                        implicitWidth: main.unitSize
                        implicitHeight: main.legendSize
                        border.color: "red"
                        border.width: 1
                        color: "transparent"
                    }
                }
            }
        }
        Loader {
            sourceComponent: debugRow
        }
        Loader {
            sourceComponent: debugLegendRow
            y: unitSize
        }
        Loader {
            sourceComponent: debugRow
            y: unitSize + legendSize
        }
        Loader {
            sourceComponent: debugLegendRow
            y: unitSize*2 + legendSize
        }
        Repeater {
            model: 5
            Loader {
                sourceComponent: debugRow
                y: (unitSize + legendSize) * 2 + index * unitSize
            }
        }
    }

    Item {
        anchors.top: infoScreen.bottom
        visible: board.debugEnabled
        Rectangle {
            width: unitSize
            height: unitSize
            border.color: "blue"
            border.width: 3
            color: "transparent"
            x: (board.selectedKnob % 8 + 1) * unitSize
            y: ~~(board.selectedKnob / 8) * (unitSize + legendSize)
        }
    }

    // route note from the sequencer to instruments
    Connections {
        target: gSequencer
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
