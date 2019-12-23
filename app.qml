import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import QtQml.StateMachine 1.0 as DSM

import Midi 1.0

Item {
    width: 600
    height: 600


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

    DSM.StateMachine {
        id: stateMachine
        initialState: s0
        running: true
        DSM.State {
            id: s0
            DSM.SignalTransition {
                targetState: s1
                signal: stack.switchToFilterEnvelope
            }
            onEntered: { stack.currentIndex = 0; }
        }
        DSM.State {
            id: s1
            DSM.SignalTransition {
                targetState: s0
                signal: stack.switchToAmplitudeEnvelope
            }
            onEntered: { stack.currentIndex = 1; }
        }
        onFinished: Qt.quit()
    }    

    StackLayout {
        id: stack
        anchors.fill:parent
        currentIndex: 0

        focus: true
        signal switchToAmplitudeEnvelope
        signal switchToFilterEnvelope
        signal keyJ
        signal keyL
        property int which_port: 0

        Timer {
            id: timer
        }
        function delay(delayTime, cb) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.start();
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_A ) {
                console.log("KeyA");
                stack.switchToAmplitudeEnvelope();
            }
            else if (event.key == Qt.Key_F ) {
                console.log("KeyF");
                stack.switchToFilterEnvelope();
            }
            else if (event.key == Qt.Key_J ) {
                console.log("KeyJ");
                midi_out.note_on(which_port, 1, 60, 64);
                delay(500, function(){
                    midi_out.note_off(which_port, 1, 60);
                });
                stack.keyJ();
            }
            else if (event.key == Qt.Key_L ) {
                which_port = 1 - which_port;
                console.log("KeyL, which_port = " + which_port);
                stack.keyL();
            }
        }

        Envelope {
            id: ampEnvelope
            title: "Amplitude Envelope"
        }

        Envelope {
            id: filterEnvelope
            title: "Filter Envelope"
        }
    }
}
