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

    DSM.StateMachine {
        id: stateMachine
        initialState: s0
        running: true
        DSM.State {
            id: s0
            DSM.SignalTransition {
                targetState: s1
                signal: stack.keyF
            }
            onEntered: { stack.currentIndex = 0; }
        }
        DSM.State {
            id: s1
            DSM.SignalTransition {
                targetState: s0
                signal: stack.keyA
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
        signal keyA
        signal keyF
        Keys.onPressed: {
            if (event.key == Qt.Key_A ) {
                console.log("KeyA");
                stack.keyA();
            }
            else if (event.key == Qt.Key_F ) {
                console.log("KeyF");
                stack.keyF();
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
