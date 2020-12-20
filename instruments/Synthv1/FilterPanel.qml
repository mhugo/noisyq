import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root
    property int synthNumber: 1

    PlacedKnobMapping {
        legend: "Cutoff"
        mapping.parameterName: "DCF" + root.synthNumber + "_CUTOFF"
        mapping.knobNumber: 2

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Reso"
        mapping.parameterName: "DCF" + root.synthNumber + "_RESO"
        mapping.knobNumber: 10

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Type"
        mapping.parameterName: "DCF" + root.synthNumber + "_TYPE"
        mapping.knobNumber: 1
        mapping.min: 0
        mapping.max: 3
        mapping.isInteger: true

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                default:
                    return "LPF";
                case 1:
                    return "BPF";
                case 2:
                    return "HPF";
                case 3:
                    return "BRF";
                }
            }
        }
    }
    PlacedKnobMapping {
        legend: "Slope"
        mapping.parameterName: "DCF" + root.synthNumber + "_SLOPE"
        mapping.knobNumber: 9
        mapping.min: 0
        mapping.max: 3
        mapping.isInteger: true

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                default:
                    return "12dB/Oct";
                case 1:
                    return "24dB/Oct";
                case 2:
                    return "Biquad";
                case 3:
                    return "Formant";
                }
            }
        }
    }

    ADSRMapping {
        startKnobNumber: 4
        attackParameter: "DCF" + root.synthNumber + "_ATTACK"
        decayParameter: "DCF" + root.synthNumber + "_DECAY"
        sustainParameter: "DCF" + root.synthNumber + "_SUSTAIN"
        releaseParameter: "DCF" + root.synthNumber + "_RELEASE"
    }

    PlacedKnobMapping {
        legend: "Envelope (?)"
        mapping.parameterName: "DCF" + root.synthNumber + "_ENVELOPE"
        mapping.knobNumber: 15
        mapping.min: -1
        mapping.max: 1

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
}
