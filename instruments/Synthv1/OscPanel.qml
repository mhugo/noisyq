import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root
    property int synthNumber: 1

    readonly property var _waveEnum: [
        "Pulse",
        "Saw",
        "Sine",
        "Rand",
        "Noise"
    ];

    PlacedKnobMapping {
        legend: "Wave"
        mapping.parameterName: "DCO" + root.synthNumber + "_SHAPE1"
        mapping.knobNumber: 1
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 4

        onValueChanged: {
            waveText1.text = _waveEnum[~~value];
        }
        Component.onCompleted: {
            waveText1.text = _waveEnum[~~value];
        }

        Text {
            id: waveText1
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ""
        }
    }

    PlacedKnobMapping {
        legend: "Wave"
        mapping.parameterName: "DCO" + root.synthNumber + "_SHAPE2"
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 4

        onValueChanged: {
            waveText2.text = _waveEnum[~~value];
        }
        Component.onCompleted: {
            waveText2.text = _waveEnum[~~value];
        }

        Text {
            id: waveText2
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ""
        }
    }

    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "DCO" + root.synthNumber + "_WIDTH1"
        mapping.knobNumber: 9

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "DCO" + root.synthNumber + "_WIDTH2"
        mapping.knobNumber: 10

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PadSwitchMapping {
        padNumber: 1
        parameterName: "DCO" + root.synthNumber + "_BANDL1"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 9
        parameterName: "DCO" + root.synthNumber + "_SYNC1"
        parameterDisplay: "Sync"
    }

    PadSwitchMapping {
        padNumber: 2
        parameterName: "DCO" + root.synthNumber + "_BANDL2"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 10
        parameterName: "DCO" + root.synthNumber + "_SYNC2"
        parameterDisplay: "Sync"
    }

    PlacedKnobMapping {
        legend: "Octave"
        mapping.parameterName: "DCO" + root.synthNumber + "_OCTAVE"
        mapping.knobNumber: 3
        mapping.min: -4.0
        mapping.max: 4.0

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Tuning"
        mapping.parameterName: "DCO" + root.synthNumber + "_TUNING"
        mapping.knobNumber: 11
        mapping.min: -1.0
        mapping.max: 1.0

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Balance"
        mapping.parameterName: "DCO" + root.synthNumber + "_BALANCE"
        mapping.knobNumber: 4
        mapping.min: -1.0
        mapping.max: 1.0

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Detune"
        mapping.parameterName: "DCO" + root.synthNumber + "_DETUNE"
        mapping.knobNumber: 5

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Phase"
        mapping.parameterName: "DCO" + root.synthNumber + "_PHASE"
        mapping.knobNumber: 13

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Ring Mod"
        mapping.parameterName: "DCO" + root.synthNumber + "_RINGMOD"
        mapping.knobNumber: 12

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
}
