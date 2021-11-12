import QtQuick 2.7
import QtQuick.Controls 2.5

import Utils 1.0

import "../../instruments/common" as Common

//
// Step sequencer
// 16 steps are visible
// within 2 rows of 8 steps

Item {
    id: sequencerDisplay

    property int step: 0
    property int oldStep: -1

    property int nPatterns: 4

    // Which pad is being pressed ?
    property int padPressed: -1

    function saveState() {
        return {
            "pattern": patternKnob.value,
            "n_patterns": nPatterns,
            "bpm": bpm.value,
            "step_duration": durationKnob.value,
            "step_note": noteKnob.value,
            "step_velocity": velocityKnob.value,
            "steps": sequencer.list_events()
        };
    }

    function loadState(state) {
        patternKnob.value = state.pattern;
        nPatterns = state.n_patterns;
        bpm.value = state.bpm;
        durationKnob.value = state.step_duration;
        noteKnob.value = state.step_note;
        velocityKnob.value = state.step_velocity;
        for (var i = 0; i < state.steps.length; i++) {
            var e = state.steps[i];
            sequencer.add_event(e.channel, e.time_amount, e.time_unit, e.event);
        }
    }

    function lightStep(step) {
        if (oldStep > -1)
            notes.itemAt(oldStep % 16).isPlaying = false;
        if (step < nPatterns * 16)
            notes.itemAt(step % 16).isPlaying = true;
        oldStep = step;
    }

    Common.PlacedDial {
        id: modeKnob
        knobNumber: 0
        enumValues: [
            "Pattern edit",
            "Step edit"
        ]
        legend: "Mode"
    }

    Common.PlacedKnobMapping {
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
        let s = ~~(step/16)*4 + step_number;
        let event = sequencer.get_event(currentVoice, s, 4);
        event[parameter_name] = value;
        sequencer.set_event(currentVoice, s, 4, event);
        _updateSteps();
    }

    Common.PlacedKnobMapping {
        id: durationKnob
        mapping.knobNumber: 9
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
        mapping.knobNumber: 10
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
        mapping.knobNumber: 11
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
    }

    Item {
        // One note per step
        y: (main.unitSize+main.legendSize) * 2
        //id: noteSequence
        //property int octave: 4
        Repeater {
            id: notes
            model: 16
            Item {
                property int velocity: 64
                property double duration: 1 // in steps
                property int note: 60 // midi note
                property bool isPlaying: false
                // FIXME add note2, note3 for triads ?
                Rectangle {
                    width: unitSize
                    height: unitSize*2
                    x: (index % 8) * unitSize
                    y: ~~(index / 8) * unitSize * 2
                    border.color: "black"
                    border.width: 1
                    color: isPlaying ? "#bbffff" : "#ffffff"
                }
                Rectangle {
                    width: unitSize * duration
                    height: unitSize * 2 / 12
                    x: (index % 8) * unitSize
                    y: ~~(index / 8) * unitSize * 2 + (unitSize * 2 - ((note % 12)+1) * height)
                    color: Qt.rgba(.0, .0, 1., velocity/127.0)
                }
            }
        }
    }

    Item {
        // icons above piano keys
        id: pianoIcons
        y: main.unitSize*6 + main.legendSize*2 + 8
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
                    sequencer.toggle_play_pause(
                        bpm.value,
                        0, 1,
                        nPatterns * 4, 1
                    );
                }
                if (note % 12 == 2) {
                    // Second note : stop
                    sequencer.stop();
                    step = 0;
                    if (oldStep > -1) {
                        notes.itemAt(oldStep % 16).isPlaying = false;
                    }
                    patternKnob.value = 1;
                    _updateSteps();
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
            sequencerDisplay.step = step;
            if (((step % 16) == 0) && (step < nPatterns * 16)) {
                patternKnob.value = ~~(step / 16)+1;
                _updateSteps();
            }
        }
    }

    function _updateSteps() {
        // Change step colors based on steps from the sequencer
        let currentVoice = ~~voiceKnob.value;
        for (var p = 0; p < 16; p++) {
            notes.itemAt(p).velocity = 0;
            notes.itemAt(p).duration = 1;
        }
        let bars = ~~(step/16);
        let events = sequencer.list_events(bars*4, 1, bars*4+4, 1);
        for (var i = 0; i < events.length; i++) {
            let event = events[i];
            if (event.channel != currentVoice)
                continue;
            // round the event start time to the previous step
            let event_time = event.time_amount / event.time_unit;
            let step_number = ~~(event_time * 4);
            //console.log("event", event.event.note, event.event.velocity);
            // FIXME handle chords
            //notes.itemAt(step_number % 16).text = Utils.midiNoteName(event.event.note);
            notes.itemAt(step_number % 16).velocity = event.event.velocity;
            notes.itemAt(step_number % 16).duration = event.event.duration_amount / event.event.duration_unit * 4;
            notes.itemAt(step_number % 16).note = event.event.note;
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
        enabled: sequencerDisplay.visible
        onNotePressed: {
            noteKnob.value = note;
            velocityKnob.value = velocity;
            if (padPressed != -1) {
                updateStepParameter(padPressed, "note", note);
                updateStepParameter(padPressed, "velocity", velocity);
            }
        }
        onPadPressed: {
            let currentVoice = ~~voiceKnob.value;
            let step = (patternKnob.value - 1) * 16 + padNumber;
            if (modeKnob.value == 1) { // Step edit
                let e = sequencer.get_event(currentVoice, step, 4);
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
                let event = sequencer.get_event(currentVoice, step, 4);
                if (event) {
                    sequencer.remove_event(currentVoice, step, 4, event);
                }
                else {
                    // add an event
                    sequencer.add_event(currentVoice,
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
        }
    }
}
