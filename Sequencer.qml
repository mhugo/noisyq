import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

RowLayout {
    id: seq

    property int nSteps: 16
    property int currentStep : -1
    property int currentVoice : 0

    function nextStep() {
        // play the current step
        currentStep = (currentStep + 1) % nSteps;
        sequencer.play_step(currentStep)
    }

    onCurrentStepChanged : {
        for (var i = 0; i < seq.nSteps; i++) {
            led.itemAt(i).color = "white";
        }
        if (currentStep >= 0)
            led.itemAt(currentStep).color = "yellow";
    }

    onCurrentVoiceChanged : {
        console.log("currentVoiceChanged");
        if (! steps.count)
            return;
        updateState();
    }

    // FIXME called from the host to initialize
    function updateState() {
        for (var i = 0; i < seq.nSteps; i++) {
            steps.itemAt(i).checked = sequencer.step(seq.currentVoice, i) != null;
        }
    }

    Timer {
        id: timer
        interval: 1 / (bpm.value / 60) * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered : {
            seq.nextStep();
        }
    }

    Button {
        id: startButton
        text: "Start"
        onClicked : {
            timer.running = ! timer.running;
            if (timer.running)
                text = "Stop";
            else {
                seq.currentStep = -1;
                text = "Start";
            }
        }
    }

    GridLayout {
        columns: seq.nSteps
        Repeater {
            id: led
            model: seq.nSteps
            Rectangle {
                radius: 90
                width: 11
                height: 11
                border.width: 1
                color: "white"
                Layout.alignment: Qt.AlignHCenter
            }
        }
        Repeater {
            id: steps
            model: seq.nSteps
            Rectangle {
                property bool checked : false
                radius: 10
                width: 48
                height: 48
                border.width: 3
                border.color: "#aaaaaa"
                color: checked ? "#777777" : "white"

                onCheckedChanged : {
                    // FIXME do not call when switching voice 
                    if (checked)
                        sequencer.set_step(seq.currentVoice, index, 60, 64, 500);
                    else
                        sequencer.unset_step(seq.currentVoice, index);
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        parent.checked = ! parent.checked;
                    }
                }
            }
        }
    }

    ColumnLayout {
        IntKnob {
            id: bpm
            text: "BPM"
            displayed_from: 1
            displayed_to: 300
            from: 1
            to: 300
            displayed_default: 120
        }
        RowLayout {
            Text { text: "Steps by beat" }
            ComboBox {
                model : ["1", "2", "4", "8", "16"]
            }
        }
    }
}
