import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    PlacedKnobMapping {
        legend: "Cutoff"
        mapping.parameterName: "DCF1_CUTOFF"
        mapping.knobNumber: 2

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Reso"
        mapping.parameterName: "DCF1_RESO"
        mapping.knobNumber: 10

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Type"
        mapping.parameterName: "DCF1_TYPE"
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
        mapping.parameterName: "DCF1_SLOPE"
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
        attackParameter: "DCF1_ATTACK"
        decayParameter: "DCF1_DECAY"
        sustainParameter: "DCF1_SUSTAIN"
        releaseParameter: "DCF1_RELEASE"
    }

    PlacedKnobMapping {
        legend: "Envelope (?)"
        mapping.parameterName: "DCF1_ENVELOPE"
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
