import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    PlacedKnobMapping {
        legend: "Wave"
        mapping.parameterName: "LFO1_SHAPE"
        mapping.knobNumber: 0
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 4

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                    return "Pulse";
                case 1:
                    return "Saw";
                case 2:
                    return "Sine";
                case 3:
                    return "Rand";
                case 4:
                    return "Noise";
                }
            }
        }
    }

    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "LFO1_WIDTH"
        mapping.knobNumber: 1

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }

    ADSRMapping {
        startKnobNumber: 4
        attackParameter: "LFO1_ATTACK"
        decayParameter: "LFO1_DECAY"
        sustainParameter: "LFO1_SUSTAIN"
        releaseParameter: "LFO1_RELEASE"
    }

    PlacedKnobMapping {
        legend: "BPM"
        mapping.parameterName: "LFO1_BPM"
        mapping.knobNumber: 8
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 360

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value
        }
    }

    PlacedKnobMapping {
        legend: "Rate"
        mapping.parameterName: "LFO1_RATE"
        mapping.knobNumber: 9

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }

    PlacedKnobMapping {
        legend: "Modulation"
        mapping.knobNumber: 14
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 7
        mapping.parameterDisplay: "Modulation"

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                    return "Sweep";
                case 1:
                    return "Pitch";
                case 2:
                    return "Balance";
                case 3:
                    return "Ring Mod";
                case 4:
                    return "Cutoff";
                case 5:
                    return "Reso";
                case 6:
                    return "Panning";
                case 7:
                    return "Volume";
                }
            }
        }

        onValueChanged : {
            modStack.currentIndex = ~~value;
        }
    }

    StackLayout {
        id: modStack
        Repeater {
            model : [
                "Sweep",
                "Pitch",
                "Balance",
                "RingMod",
                "Cutoff",
                "Reso",
                "Panning",
                "Volume"
            ]
            PlacedKnobMapping {
                legend: modelData
                mapping.parameterName: "LFO1_" + modelData.toUpperCase()
                mapping.knobNumber: 15
                mapping.min: -1
                mapping.max: 1
                
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(1)
                }
            }
        }
    }
}
