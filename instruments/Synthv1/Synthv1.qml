import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

import "../common"

Item {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://synthv1.sourceforge.net/lv2"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Synthv1"

    // Set by the host
    property int unitSize: 100

    readonly property int legendSize: 0.3 * unitSize

    implicitWidth: unitSize * 8
    implicitHeight: unitSize * 2 + legendSize * 2


    //------------------ custom properties

    property string sampleFileName

    function saveState() {
        let d = {};
        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.parameterName != undefined) {
                d[child.parameterName] = child.value;
                continue;
            }
        }
        
        return {
            "sampleFileName" : sampleFileName,
            "parameters" : d
        };
    }

    function loadState(state) {
        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.parameterName != undefined) {
                if (child.parameterName in state.parameters) {
                    child.value = state.parameters[child.parameterName];
                    continue;
                }
            }
        }
    }

    // Initialize a state, reading from the living LV2 process
    function init() {
        console.log("synthv1 init");
    }

    Item {
        id: debug_grid
        GridLayout {
            columns: 8
            columnSpacing: 0
            rowSpacing: 0
            // first knob block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: unitSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // first legend block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: legendSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // second knob block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: unitSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // second legend block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: legendSize
                    border.color: "red"
                    border.width: 1
                }
            }
        }
    }

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
        mapping.knobNumber: 0
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
        mapping.knobNumber: 1
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
        mapping.knobNumber: 8

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PlacedKnobMapping {
        legend: "Width"
        mapping.parameterName: "DCO1_WIDTH2"
        mapping.knobNumber: 9

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: ~~(parent.value * 100) + "%"
        }
    }

    PadSwitchMapping {
        padNumber: 0
        parameterName: "DCO1_BANDL1"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 8
        parameterName: "DCO1_SYNC1"
        parameterDisplay: "Sync"
    }

    PadSwitchMapping {
        padNumber: 1
        parameterName: "DCO1_BANDL2"
        parameterDisplay: "Band\nLimited"
    }
    PadSwitchMapping {
        padNumber: 9
        parameterName: "DCO1_SYNC2"
        parameterDisplay: "Sync"
    }

    PlacedKnobMapping {
        legend: "Octave"
        mapping.parameterName: "DCO1_OCTAVE"
        mapping.knobNumber: 2
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
        mapping.knobNumber: 10
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
        mapping.knobNumber: 3
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
        mapping.knobNumber: 4

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Phase"
        mapping.parameterName: "DCO1_PHASE"
        mapping.knobNumber: 12

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    PlacedKnobMapping {
        legend: "Ring Mod"
        mapping.parameterName: "DCO1_RINGMOD"
        mapping.knobNumber: 11

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.updateText(7, "Back");
        }
    }

    // will be called by main
    function padPressed(padNumber) {
    }

    // will be called by main
    function padReleased(padNumber) {
        if (padNumber == 7) {
            // end of editing
            canvas.endEditInstrument();            
        }
    }

}
