import QtQuick 2.7
import QtQuick.Controls 2.5

import Utils 1.0

import "../../instruments/common" as Common

Item {
    id: sequencerDisplay

    property int step: 0
    property string oldColor: Pad.Color.Black
    property int oldStep: -1

    property int nPatterns: 4

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
    
    Common.PlacedKnobMapping {
        id: patternKnob
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 1
        mapping.max: nPatterns
        mapping.value: 1
        mapping.shiftMin: 1
        mapping.shiftMax: 16
        mapping.shiftValue: nPatterns
        Common.NumberFrame {
            value: parent.value
            max: parent.shiftValue
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

    Item {
        // all pads
        y: (main.unitSize+main.legendSize) * 2
        Repeater {
            id: pads
            model: 16
            PadText {
                padNumber: index
            }
        }
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
            if ((step % 16) == 0) {
                patternKnob.value = ~~(step / 16)+1;
                _updateSteps();
            }
        }
    }

    function _updateSteps() {
        // Change step colors based on steps from the sequencer
        let currentVoice = ~~voiceKnob.value;
        for (var p = 0; p < 16; p++) {
            padRep.itemAt(p).color = Pad.Color.Black;
            pads.itemAt(p).text = "";
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
            pads.itemAt(step_number % 16).text = Utils.midiNoteName(event.event.note);
            Qt.callLater(function(){padRep.itemAt(step_number % 16).color = Pad.Color.Blue});
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
