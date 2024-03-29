import QtQuick 2.7
import QtQuick.Controls 2.5

import Utils 1.0
import PianoRoll 1.0

import "../../instruments/common" as Common

//
// Step sequencer
// 16 steps are visible
// within 2 rows of 8 steps
Item {
    id: sequencerDisplay

    property int step: 0
    property int oldStep: -1

    // Which pad is being pressed ?
    property int padPressed: -1

    function saveState() {
        return {
            "n_beats": ~~gSequencer.n_steps,
            //"offset": timeOffsetKnob.value,
            "note_offset": ~~pianoRoll.note_offset,
            "bpm": ~~bpmKnob.value,
            "time_signature": ~~timeSignatureKnob.value,
            "bars_per_screen": ~~barsPerScreenKnob.value,
            "n_bars": ~~nBarsKnob.value,
            "cursor_width": ~~cursorWidth.value,
            "velocity": ~~velocityKnob.value,
            "steps": gSequencer.list_events()
        };
    }

    function loadState(state) {
        //n_stepsKnob.value = state.n_beats;
//        timeOffsetKnob.value = state.offset;
        pianoRoll.note_offset = state.note_offset;
        bpmKnob.value = state.bpm;
        timeSignatureKnob.value = state.time_signature;
        barsPerScreenKnob.value = state.bars_per_screen;
        nBarsKnob.value = state.n_bars;
        cursorWidth.value = state.cursor_width;
        velocityKnob.value = state.velocity;
        for (var i = 0; i < state.steps.length; i++) {
            var e = state.steps[i];
            gSequencer.add_event(e.channel, e.time, e.event);
        }
    }

    Common.PlacedDial {
        id: modeKnob
        knobNumber: 0
        enumValues: [
            "Select",
            "Edit",
            "Step record",
            "Live record",
        ]
        legend: "Mode"
        color: "#ffaaaa"
    }

/*    Common.PlacedKnobMapping {
        id: bpm
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 20
        mapping.max: 300
        mapping.value: 120
        Common.NumberFrame {
            value: ~~parent.value
            displaySign: false
            text: "BPM"
        }
    }
    
    Common.PlacedKnobMapping {
        id: patternKnob
        mapping.knobNumber: 3
        mapping.isInteger: true
        mapping.min: 1
        mapping.max: nPatterns
        mapping.value: 1
        mapping.shiftMin: 1
        mapping.shiftMax: 16
        mapping.shiftValue: nPatterns
        Common.NumberFrame {
            value: ~~parent.value
            max: ~~parent.shiftValue
            displaySign: false
            text: "Pattern"

            onValueChanged: {
                step = (value-1) * 16;
                _updateSteps();
            }
            onMaxChanged: {
                nPatterns = max;
                if (max < parent.value)
                    parent.value = max;
            }
        }
    }

    function updateStepParameter(step_number, parameter_name, value) {
        let currentVoice = ~~voiceKnob.value;
        let s = ~~(step/16)*16 + step_number;
        let event = gSequencer.get_event(currentVoice, s, 4);
        event[parameter_name] = value;
        gSequencer.set_event(currentVoice, s, 4, event);
        _updateSteps();
    }

    Common.PlacedKnobMapping {
        id: durationKnob
        mapping.knobNumber: 10
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 5
        mapping.value: 4

        function setFromDuration(amount, unit) {
            if ((amount == 4) && (unit == 1)) {
                value = 0;
            }
            else if ((amount == 2) && (unit == 1)) {
                value = 1;
            }
            else if ((amount == 1) && (unit == 1)) {
                value = 2;
            }
            else if ((amount == 1) && (unit == 2)) {
                value = 3;
            }
            else if ((amount == 1) && (unit == 4)) {
                value = 4;
            }
            else if ((amount == 1) && (unit == 8)) {
                value = 5;
            }
        }
        function toAmount() {
            switch (~~value) {
            case 0:
                return 4;
            case 1:
                return 2;
            case 2:
                return 1;
            case 3:
                return 1;
            case 4:
                return 1;
            case 5:
                return 1;
            }
        }
        function toUnit() {
            switch (~~value) {
            case 0:
                return 1;
            case 1:
                return 1;
            case 2:
                return 1;
            case 3:
                return 2;
            case 4:
                return 4;
            case 5:
                return 8;
            }
        }
        Common.FramedText {
            legend: "Duration"
            text: {
                switch (~~parent.value) {
                case 0:
                    return "4/1";
                case 1:
                    return "2/1";
                case 2:
                    return "1/1";
                case 3:
                    return "1/2";
                case 4:
                    return "1/4";
                case 5:
                    return "1/8";
                }
            }
        }
        onValueChanged: {
            if (padPressed != -1) {
                updateStepParameter(padPressed, "duration_amount", durationKnob.toAmount());
                updateStepParameter(padPressed, "duration_unit", durationKnob.toUnit());
            }
        }
    }

    Common.PlacedKnobMapping {
        id: noteKnob
        mapping.knobNumber: 11
        mapping.isInteger: true
        mapping.min: 20
        mapping.max: 100
        mapping.value: 60
        Common.FramedText {
            legend: "Note"
            text: Utils.midiNoteName(~~parent.value)
        }

        onValueChanged: {
            if (padPressed != -1) {
                updateStepParameter(padPressed, "note", value);
            }
        }
    }

    Common.PlacedKnobMapping {
        id: velocityKnob
        mapping.knobNumber: 12
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 127
        mapping.value: 64
        Common.FramedText {
            legend: "Velocity"
            text: ~~parent.value
        }
        onValueChanged: {
            if (padPressed != -1) {
                updateStepParameter(padPressed, "velocity", value);
            }
        }
    }*/

    Rectangle {
        // upper part of the piano roll
        y: (main.unitSize+main.legendSize) * 2 + unitSize
        height: unitSize
        width: 8 * unitSize
        color: "white"

    }
    ScrollBar {
        y: (main.unitSize+main.legendSize) * 2 + unitSize
        width: 8*unitSize
        policy: ScrollBar.AlwaysOn
        orientation: Qt.Horizontal
        size: 1.0 / gSequencer.n_steps
        position: xOffset.value / gSequencer.n_steps
    }

    PianoRoll {
        id: pianoRoll
        width: 8 * unitSize
        height: unitSize * 2
        y: (main.unitSize+main.legendSize) * 2 + 2*unitSize

        sequencer: gSequencer
        channel: ~~voiceKnob.value

        barsPerScreen: 2
    }

    // Common pads for all modes

    Common.PlacedNoValueKnob {
        id: xOffset
        knobNumber: 1

        Common.FramedText {
            legend: "Cursor X"
            text: "<X>"
        }

        function onIncrement() {
            pianoRoll.increment_cursor_x();
        }
        function onDecrement() {
            pianoRoll.decrement_cursor_x();
        }

        Connections {
            target: board
            onKeyLeft: {
                xOffset.onDecrement();
            }
            onKeyRight: {
                xOffset.onIncrement();
            }
            enabled: !board.isShiftPressed
        }

        visible: !board.isShiftPressed
    }
    Common.PlacedNoValueKnob {
        id: yOffset
        knobNumber: 9

        Common.FramedText {
            legend: "Cursor Y"
            text: "<Y>"
        }

        function onIncrement() {
            pianoRoll.increment_cursor_y();
        }
        function onDecrement() {
            pianoRoll.decrement_cursor_y();
        }

        Connections {
            target: board
            onKeyDown: {
                yOffset.onDecrement();
            }
            onKeyUp: {
                yOffset.onIncrement();
            }
            enabled: !board.isShiftPressed
        }
        visible: !board.isShiftPressed;
    }

    
    Common.PlacedKnobMapping {
        id: bpmKnob
        mapping.knobNumber: 10
        mapping.isInteger: true
        mapping.min: 20
        mapping.max: 300
        mapping.value: 120
        Common.FramedText {
            legend: "BPM"
            text: ~~parent.value
        }
        visible: !board.isShiftPressed;
    }

    Common.PlacedKnobMapping {
        id: timeSignatureKnob
        mapping.knobNumber: 10
        mapping.isInteger: true

        /*
        readonly property var numberOfNotes: [
            2,
            3,
            4,
            2,
            6,
            9,
            12
        ]
        readonly property var unit: [
            4,
            4,
            4,
            2,
            8,
            8,
            8
        ]*/
        readonly property var numberOfNotes: [
            4,
            4
        ]
        readonly property var unit: [
            4,
            8
        ]
        mapping.min: 0
        mapping.max: 1
        mapping.value: 0
        Common.FramedText {
            legend: "Time sig."
            Text {
                text: timeSignatureKnob.numberOfNotes[~~timeSignatureKnob.value] + "/" + timeSignatureKnob.unit[~~timeSignatureKnob.value]
                x: (parent.width - width) / 2
                y: (parent.height - height) / 3
            }
        }
        onValueChanged: {
            gSequencer.setTimeSignature(timeSignatureKnob.numberOfNotes[~~value], timeSignatureKnob.unit[~~value]);
        }
        visible: board.isShiftPressed;
    }

    Common.PlacedKnobMapping {
        id: barsPerScreenKnob
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 1
        mapping.max: 64
        mapping.value: 2
        Common.FramedText {
            legend: "Bars / screen"
            text: ~~parent.value
        }
        onValueChanged: {
            pianoRoll.barsPerScreen = value
        }
        visible: !board.isShiftPressed;
    }

    Common.PlacedKnobMapping {
        id: nBarsKnob
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 1
        mapping.max: 64
        mapping.value: 2
        Common.FramedText {
            legend: "# Bars"
            text: ~~parent.value
        }
        onValueChanged: {
            gSequencer.n_bars = ~~value
            pianoRoll.update()
            
        }
        visible: board.isShiftPressed;
    }

    Common.PlacedKnobMapping {
        id: cursorWidth
        mapping.knobNumber: 1
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 5
        mapping.value: 2

        property int amount: 1
        property int unit: 1
        Common.FramedText {
            text: parent.amount + "/" + parent.unit
            legend: "Cursor width"
        }

        onValueChanged: {
            amount = [1,  1,  1, 1, 1, 2, 3, 4][~~value];
            unit =   [32, 16, 8, 4, 2, 1, 1, 1][~~value];
            //pianoRoll.set_cursor_width(amount, unit);
            pianoRoll.set_cursor_width(amount * 256 / unit);
        }

        Connections {
            target: board
            onKeyLeft: {
                board.decrementKnob(cursorWidth.mapping.knobNumber, 1);
            }
            onKeyRight: {
                board.incrementKnob(cursorWidth.mapping.knobNumber, 1);
            }
            enabled: board.isShiftPressed
        }

        visible: board.isShiftPressed;
    }

    Common.PlacedKnobMapping {
        id: velocityKnob
        mapping.knobNumber: 9
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 127
        mapping.value: 64

        Common.FramedVuMeter {
            value: parent.value
            max: 127.0
            legend: "Velocity"
        }

        Connections {
            target: board
            onKeyDown: {
                board.decrementKnob(velocityKnob.mapping.knobNumber, 1);
            }
            onKeyUp: {
                board.incrementKnob(velocityKnob.mapping.knobNumber, 1);
            }
            enabled: board.isShiftPressed
        }

        visible: board.isShiftPressed;
    }

    Common.PlacedNoValueKnob {
        id: loopKnob
        knobNumber: 6

        property bool looped: true

        Common.FramedText {
            Image {
                id: loopImage
                source: "loop.png"
                width: unitSize / 2
                height: unitSize / 2
                x: (unitSize - width) / 2
                y: (unitSize - height) / 2
            }
        }

        function onIncrement() {
            loopImage.source = "loop.png";
            looped = true;
        }
        function onDecrement() {
            loopImage.source = "no_loop.png";
            looped = false;
        }
    }

    Item {
        Common.PlacedPadText {
            // Pads for select mode
            visible: ~~modeKnob.value == 0

            padNumber: 0
            text: "SLCT"

            onPadReleased: {
                let note = pianoRoll.note_offset + pianoRoll.cursor_y;
                let start = pianoRoll.cursor_start()
                let stop = pianoRoll.cursor_end()

                let events = gSequencer.list_events(start, stop);
                for (var i=0; i < events.length; i++) {
                    let event = events[i];
                    if (event.channel == voiceKnob.value && event.event.event_type == "note_event" && event.event.note == note)
                        pianoRoll.toggleNoteSelection(event.channel, event.time_amount, event.time_unit, note);
                }
                pianoRoll.update();
            }
        }

        Common.PlacedPadText {
            // Pads for record mode
            visible: ~~modeKnob.value == 2

            padNumber: 7
            text: "ERASE"

            onPadReleased: {
                let currentVoice = ~~voiceKnob.value;
                gSequencer.remove_events_in_range(
                    currentVoice,
                    pianoRoll.cursor_start(),
                    pianoRoll.cursor_end());
                pianoRoll.update();
            }
        }
    }
    
    Item {
        // icons above piano keys
        id: pianoIcons
        y: main.unitSize*6 + main.legendSize*2 + 8
        readonly property real keyWidth: (main.width - piano.octaveWidth - unitSize) / 15
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
        Image {
            source: "rec.svg"
            width: 16
            height: 16
            x: (parent.keyWidth - width) / 2 + 2 * parent.keyWidth
            SequentialAnimation on visible {
                id: recAnimation
                running: false
                loops: Animation.Infinite
                PropertyAnimation { to: false }
                PropertyAnimation { to: true }
            }
        }
    }

    Connections {
        target: gSequencer
        onStateChanged: {
            pianoIcons.isPlaying = gSequencer.is_playing();
        }
    }

    function _updateSteps() {
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

    property var notes: []
    property var noteStarts: []
    property real previousNoteOnTs: 0
    property real previousNoteOffTs: 0
    readonly property int chordTimeout: 200 // milliseconds

    Connections {
        target: board
        enabled: sequencerDisplay.visible
        onNotePressed: {
            if (!board.isShiftPressed) {
                if ((~~modeKnob.value == 2) && recAnimation.running) { // step record
                    let ts = Date.now();
                    notes.push(note);
                    noteStarts.push({"time": pianoRoll.cursor_start()});
                    if ((previousNoteOnTs != 0) && (ts - previousNoteOnTs > chordTimeout))
                        pianoRoll.increment_cursor_x();
                    let currentVoice = ~~voiceKnob.value;
                    gSequencer.remove_events_in_range(
                        currentVoice,
                        pianoRoll.cursor_start(),
                        pianoRoll.cursor_end());
                    previousNoteOnTs = ts;
                    previousNoteOffTs = 0;
                }
                pianoRoll.noteOn(note);
            }
        }
        onNoteReleased: {
            if (board.isShiftPressed) {
                if (note % 12 == 0) {
                    // First note : play/pause
                    gSequencer.toggle_play_pause(
                        bpmKnob.value,
                        0,
                        ~~gSequencer.n_steps,
                        loopKnob.looped
                    );
                }
                else if (note % 12 == 2) {
                    // Second note : stop
                    gSequencer.stop(false);
                    step = 0;
                    if (oldStep > -1) {
                        notes.itemAt(oldStep % 16).isPlaying = false;
                    }
                    //patternKnob.value = 1;
                    _updateSteps();
                }
                else if (note % 12 == 4) {
                    // Third note : record
                    recAnimation.running = ! recAnimation.running;
                }
            }
            else {
                pianoRoll.noteOff(note);

                if ((~~modeKnob.value == 2) && recAnimation.running) { // step record
                    let currentVoice = ~~voiceKnob.value;
                    let ts = Date.now();
                    let idx = notes.indexOf(note);
                    if ((previousNoteOffTs != 0) && (ts - previousNoteOffTs > chordTimeout))
                        pianoRoll.increment_cursor_x();

                    let start = noteStarts[idx].time;
                    let end = pianoRoll.cursor_end();
                    let duration = end - start;
                    let velocity = velocityKnob.value;
                    notes.splice(idx, 1);
                    noteStarts.splice(idx, 1);
                    previousNoteOffTs = ts;
                    previousNoteOnTs = 0;

                    gSequencer.add_event(currentVoice,
                                         start,
                                         {
                                             "event_type": "note_event",
                                             "note": note,
                                             "velocity": velocity,
                                             "duration": duration,
                                         });
                    if ((pianoRoll.note_offset <= note - 12) || (pianoRoll.note_offset >= note)) {
                        pianoRoll.note_offset = note
                    }
                    if (notes.length == 0)
                        pianoRoll.increment_cursor_x();
                }
            }

        }
        /*onPadPressed: {
            let currentVoice = ~~voiceKnob.value;
            let step = (patternKnob.value - 1) * 16 + padNumber;
            if (modeKnob.value == 1) { // Step edit
                let e = gSequencer.get_event(currentVoice, step, 4);
                if (e) {
                    noteKnob.value = e.note;
                    velocityKnob.value = e.velocity;
                    durationKnob.setFromDuration(e.duration_amount, e.duration_unit);
                }
                padPressed = padNumber;
            }
        }
        onPadReleased: {
            let currentVoice = ~~voiceKnob.value;
            let step = (patternKnob.value - 1) * 16 + padNumber;
            if (modeKnob.value == 0) { // Pattern edit
                // toggle step
                let event = gSequencer.get_event(currentVoice, step, 4);
                if (event) {
                    gSequencer.remove_event(currentVoice, step, 4, event);
                }
                else {
                    // add an event
                    gSequencer.add_event(currentVoice,
                                        step,
                                        4,
                                        {
                                            "event_type": "note_event",
                                            "note": noteKnob.value,
                                            "velocity": velocityKnob.value,
                                            "duration_amount": durationKnob.toAmount(),
                                            "duration_unit": durationKnob.toUnit()
                                        });
                }
                sequencerDisplay._updateSteps();
            }
            padPressed = -1;
            }*/
    }
}
