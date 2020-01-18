import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import QtQml.StateMachine 1.0 as DSM

import Midi 1.0

Item {
    id: main
    width: 600
    height: 600

    // French keyboard scan codes
    Item {
        id: keycode
        property int k_escape : 9
        property int k_a : 24
        property int k_z : 25
        property int k_f : 41
        property int k_j : 44
        property int k_w : 52
        property int k_x : 53
        property int k_c : 54
        property int k_v : 55
        property int k_b : 56
        property int k_n : 57
        property int k_comma : 58
        property int k_semi_colon : 59
        property int k_colon : 60
        property int k_exclamation : 61
    }

    MidiIn {
        id: midi_in
        port: Qt.application.arguments[1] || ""

        onDataReceived : {
            console.log(data);
            if ( (data[0] == 0xB1) && (data[1] == 1) ) {
                adsr.attack = data[2] / 127.0 * 16;
            }
        }
    }
    MidiOut {
        id: midi_out
        ports: ["midi_out1", "midi_out2"]
    }

    StackLayout {
        id: stack
        anchors.fill:parent
        currentIndex: 0

        // grab keyboard events
        focus: true

        signal keyPressed(int code, int key)
        signal keyReleased(int code, int key)

        // switch to a given item by its id
        function switchTo(item) {
            for (var idx=0; idx < children.length; idx++) {
                let child = children[idx];
                if (item === child) {
                    currentIndex = idx;
                    break;
                }
            }
        }

        Keys.onPressed: {
            if (! event.isAutoRepeat) {
                console.log("scan code " + event.nativeScanCode);
                keyPressed(event.nativeScanCode, event.key);
            }
        }
        Keys.onReleased: {
            keyReleased(event.nativeScanCode, event.key);
        }

        Envelope {
            id: ampEnvelope
            title: "Amplitude Envelope"
        }

        Envelope {
            id: filterEnvelope
            title: "Filter Envelope"
        }

        RowLayout {
            id: osc1Panel
            EnumKnob {
                text: "W"
                enums: ["sin",
                        "triangle",
                        "square",
                        "saw up",
                        "saw down",
                        "3 step",
                        "4 step",
                        "8 step",
                        "3 pyramid",
                        "5 pyramid",
                        "9 pyramid"]

                onValueChanged : {
                    console.log("changed to " + value + " " + value);
                    // send as channel 1, CC 1
                    midi_out.cc(0, 0, 1, Math.round(value*127));
                    // send to jalv control
                    jalv.setControl("osc_1_waveform", value);
                }
                Component.onCompleted : {
                    value = jalv.getControl("osc_1_waveform");
                    console.log("enums.length " + enums.length + " value " + value);
                    console.log("EnumKnob onCompleted, value = " + value);
                }
            }
            IntKnob {
                text: "T"
                units: "semitones"
                displayed_from: -48.0
                displayed_to: 48.0
                displayed_default: 0.0
                onValueChanged : {
                    console.log("changed to " + value + " " + ~~(value));
                    // send as channel 1, CC 2
                    midi_out.cc(0, 0, 2, Math.round(value*127));
                }
            }
            Knob {
                text: "t"
                units: "cents"
                from: -100.0
                to: 100.0
                onValueChanged : {
                    console.log("changed to " + value + " " + ~~(value));
                    // send as channel 1, CC 3
                    midi_out.cc(0, 0, 3, Math.round((value+100.0)/200.0*127));
                }
            }
        }
    }
    JALVWrapper {
        id: jalv
        Component.onCompleted : {
            setInstance("http://tytel.org/helm", "Helm1");
            console.log("jalv oncompleted")
        }
    }

        Timer {
            id: timer
        }
        function delay(delayTime, cb) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.start();
        }

    Connections {
        target: stack

        onKeyPressed: {
            if (code == keycode.k_escape) {
                Qt.quit();
            }
            if (code == keycode.k_a) {
                stack.switchTo(ampEnvelope);
            }
            else if (code == keycode.k_f) {
                stack.switchTo(filterEnvelope);
            }
            else if (code == keycode.k_z) {
                stack.switchTo(osc1Panel);
            }
            else if ((code >= keycode.k_w) && (code <= keycode.k_exclamation)) {
                // 69 : A4
                let note = code - keycode.k_w + 69
                midi_out.note_on(0, 1, note, 64);
                delay(500, function(){
                    midi_out.note_off(0, 1, note);
                });                
            }
        }
        onKeyReleased: {
            if ((code >= keycode.k_w) && (code <= keycode.k_exclamation)) {
                // 69 : A4
                let note = code - keycode.k_w + 69
                midi_out.note_off(0, 1, note);
            }
        }
    }
}
