import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    readonly property var _waveEnum: [
        "Pulse",
        "Saw",
        "Sine",
        "Rand",
        "Noise"
    ];

    PlacedKnobMapping {
        legend: "Wave"
        mapping.parameterName: "DCO1_SHAPE1"
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
        mapping.parameterName: "DCO1_SHAPE2"
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
        mapping.parameterName: "DCO1_WIDTH1"
        mapping.knobNumber: 9

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "DCO1_WIDTH2"
        mapping.knobNumber: 10

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PadSwitchMapping {
        padNumber: 1
        parameterName: "DCO1_BANDL1"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 9
        parameterName: "DCO1_SYNC1"
        parameterDisplay: "Sync"
    }

    PadSwitchMapping {
        padNumber: 2
        parameterName: "DCO1_BANDL2"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 10
        parameterName: "DCO1_SYNC2"
        parameterDisplay: "Sync"
    }

    PlacedKnobMapping {
        legend: "Octave"
        mapping.parameterName: "DCO1_OCTAVE"
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
        mapping.parameterName: "DCO1_TUNING"
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
        mapping.parameterName: "DCO1_BALANCE"
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
        mapping.parameterName: "DCO1_DETUNE"
        mapping.knobNumber: 5

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Phase"
        mapping.parameterName: "DCO1_PHASE"
        mapping.knobNumber: 13

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Ring Mod"
        mapping.parameterName: "DCO1_RINGMOD"
        mapping.knobNumber: 12

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
}
