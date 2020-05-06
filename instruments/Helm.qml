import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import MyUtils 1.0

GridLayout {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://tytel.org/helm"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Helm"

    // shortcut
    function _setLV2(param, value) {
        lv2Host.setParameterValue(lv2Id, param, value);
    }

    // Automatically save values of objects with "saveState" property defined
    // Use its id as parameter name
    function saveState() {
        let d = {};
        for (var i = 0; i < root.children.length; i++) {
            let child = root.children[i];
            if (child.saveState != undefined) {
                let id = MyUtils.objectId(child);
                d[id] = child.value;
            }
        }
        return d;
    }

    function loadState(state) {
        console.log("loadState", state);
        for (var i = 0; i < root.children.length; i++) {
            let child = root.children[i];
            if (child.saveState != undefined) {
                let id = MyUtils.objectId(child);
                if (id in state) {
                    child.value = state[id];
                }
            }
        }
    }

    columns: 8

    property var waveEnum : ["sin",
                             "triangle",
                             "square",
                             "saw up",
                             "saw down",
                             "3 step",
                             "4 step",
                             "8 step",
                             "3 pyramid",
                             "5 pyramid",
                             "9 pyramid"]

    // First row
    Text {
        text: "---"
        Layout.columnSpan: 8
    }

    // Second row
    Text {
        text: "Vol."
    }

    Text {
        text: "---"
        Layout.columnSpan: 7
    }

    // Third row
    Slider {
        id: osc_1_volume
        property bool saveState: true

        from: 0.0
        to: 16.0
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2("osc_1_volume", value);
        }
    }

    StackLayout {
        id: osc_1_waveform
        property bool saveState: true
        property alias value: osc_1_waveform.currentIndex

        Layout.fillHeight: true
        Repeater {
            id: rep
            model: waveEnum
            Text {
                text: modelData
            }
        }

        onCurrentIndexChanged: {
            _setLV2("osc_1_volume", currentIndex / (rep.count - 1));
        }
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
            infoScreen.text = "Helm";

            board.setKnobIsInteger(1, true);
            board.setKnobMinMax(1, 0, waveEnum.length-1);
            board.setKnobValue(1, osc_1_waveform.currentIndex);

            board.setKnobIsInteger(0, false);
            board.setKnobMinMax(0, 0, 16);
            board.setKnobValue(0, osc_1_volume.value);
        }
    }

    Connections {
        target: board

        // only visible panels should react to knob / pad changes
        enabled: root.visible

        onKnobMoved : {
            switch (knobNumber) {
            case 0:
                osc_1_volume.value = amount;
                break;
            case 1:
                osc_1_waveform.value = ~~amount;
                break;
            }
        }
    }
}


