import QtQuick 2.7
import QtQuick.Controls 2.5

import Utils 1.0
import "../../instruments/common" as Common

Item {
    id: mixer
    property int voiceSelected: -1

    function refresh() {
        visible = false;
        Utils.processEvents();
        visible = true;
    }

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
                mixer.refresh();
            }
        }

        onPadDoubleTapped: {
            if (padNumber < 8) {
                let instr = instrumentStack.instrumentAt(padNumber);
                if (lv2Host.isSolo(instr.instrument.lv2Id)) {
                    lv2Host.unsetSolo(instr.instrument.lv2Id);
                }
                else {
                    lv2Host.setSolo(instr.instrument.lv2Id);
                }
                mixer.refresh();
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
                    let solo = (instr !== undefined) && lv2Host.isSolo(instr.instrument.lv2Id);
                    let color = muted ? Board.Color.Red : (solo ? Board.Color.Purple : Board.Color.Black);
                    board.setPadColor(index, color);
                    padRep.itemAt(index).color = color;
                }
            }
        }
    }

    Text {
        y: unitSize + legendSize
        x: unitSize
        text: "Knob 1 click: mute/unmute voice\nDouble tap: solo/unsolo voice"
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
