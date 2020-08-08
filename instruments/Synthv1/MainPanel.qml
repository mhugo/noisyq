import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root
    property int synthNumber: 1

    PlacedKnobMapping {
        legend: "DCA Volume"
        mapping.parameterName: "DCA" + root.synthNumber + "_VOLUME"
        mapping.knobNumber: 0

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }

    ADSRMapping {
        startKnobNumber: 4
        attackParameter: "DCA" + root.synthNumber + "_ATTACK"
        decayParameter: "DCA" + root.synthNumber + "_DECAY"
        sustainParameter: "DCA" + root.synthNumber + "_SUSTAIN"
        releaseParameter: "DCA" + root.synthNumber + "_RELEASE"
    }

    PlacedKnobMapping {
        legend: "Velocity"
        mapping.parameterName: "DEF" + root.synthNumber + "_VELOCITY"
        mapping.knobNumber: 14

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
    PlacedKnobMapping {
        legend: "Mono / Poly"
        mapping.parameterName: "DEF" + root.synthNumber + "_MONO"
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
        mapping.parameterName: "OUT" + root.synthNumber + "_VOLUME"
        mapping.knobNumber: 8

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "OUT" + root.synthNumber + "_WIDTH"
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
        mapping.parameterName: "OUT" + root.synthNumber + "_PANNING"
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
        mapping.parameterName: "OUT" + root.synthNumber + "_FXSEND"
        mapping.knobNumber: 11

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: (parent.value * 100).toFixed(2) + "%"
        }
    }
}
