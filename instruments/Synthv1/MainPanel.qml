import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root
    property int synthNumber: 1

    PlacedKnobMapping {
        legend: "DCA Vol."
        mapping.parameterName: "DCA" + root.synthNumber + "_VOLUME"
        mapping.knobNumber: 0

        text: (value * 100).toFixed(0) + "%"
    }

    PlacedKnobMapping {
        legend: "Env. time"
        mapping.parameterName: "DCO" + root.synthNumber + "_ENVTIME"
        mapping.knobNumber: 3

        text: (value * 10).toFixed(0) + "s"
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

        text: (value * 100).toFixed(0) + "%"
    }
    PlacedKnobMapping {
        legend: "Polyphony"
        mapping.parameterName: "DEF" + root.synthNumber + "_MONO"
        mapping.knobNumber: 15
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 2

        text: {
            switch (value) {
            case 0:
            default:
                return "Mono";
            case 1:
                return "Poly";
            case 2:
                return "Legato";
            }
        }
    }

    PlacedKnobMapping {
        legend: "OUT Vol."
        mapping.parameterName: "OUT" + root.synthNumber + "_VOLUME"
        mapping.knobNumber: 8

        text: (value * 100).toFixed(0) + "%"
    }
    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "OUT" + root.synthNumber + "_WIDTH"
        mapping.knobNumber: 9
        mapping.min: -1
        mapping.max: 1

        text: value.toFixed(2)
    }
    PlacedKnobMapping {
        legend: "Panning"
        mapping.parameterName: "OUT" + root.synthNumber + "_PANNING"
        mapping.knobNumber: 10
        mapping.min: -1
        mapping.max: 1

        text: value.toFixed(2)
    }
    PlacedKnobMapping {
        legend: "FX Send"
        mapping.parameterName: "OUT" + root.synthNumber + "_FXSEND"
        mapping.knobNumber: 11

        text: (value * 100).toFixed(0) + "%"
    }
}
