import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    PlacedKnobMapping {
        legend: "DCA Volume"
        mapping.parameterName: "DCA1_VOLUME"
        mapping.knobNumber: 0

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }

    ADSRMapping {
        startKnobNumber: 4
        attackParameter: "DCA1_ATTACK"
        decayParameter: "DCA1_DECAY"
        sustainParameter: "DCA1_SUSTAIN"
        releaseParameter: "DCA1_RELEASE"
    }

    PlacedKnobMapping {
        legend: "Velocity"
        mapping.parameterName: "DEF1_VELOCITY"
        mapping.knobNumber: 14

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
    PlacedKnobMapping {
        legend: "Mono / Poly"
        mapping.parameterName: "DEF1_MONO"
        mapping.knobNumber: 15
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 2

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                    return "Mono";
                case 1:
                    return "Poly";
                case 2:
                    return "Legato";
                }
            }
        }
    }

    PlacedKnobMapping {
        legend: "OUT Volume"
        mapping.parameterName: "OUT1_VOLUME"
        mapping.knobNumber: 8

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "OUT1_WIDTH"
        mapping.knobNumber: 9
        mapping.min: -1
        mapping.max: 1

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
    PlacedKnobMapping {
        legend: "Panning"
        mapping.parameterName: "OUT1_PANNING"
        mapping.knobNumber: 10
        mapping.min: -1
        mapping.max: 1

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
    PlacedKnobMapping {
        legend: "FX Send"
        mapping.parameterName: "OUT1_FXSEND"
        mapping.knobNumber: 11

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
}
