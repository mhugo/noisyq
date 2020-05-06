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
    function _setLV2(obj, value) {
        lv2Host.setParameterValue(lv2Id, MyUtils.objectId(obj), value);
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
    RowLayout {
        Layout.columnSpan: 8
        Rectangle {
            width: 100
            height: 4
            color: "black"
        }
        Text {
            text: "---[ OSC 1 ]---"
        }
        Text {
            text: "---[ OSC 1 ]---"
        }
    }

    // Second row
    Text {
        text: "Vol."
    }

    Text {
        text: "Shape"
    }

    Text {
        text: "Tune"
    }

    Text {
        text: "Transp."
    }

    Text {
        text: "Voices"
    }

    Text {
        text: "V. detune"
    }

    Text {
        text: "---"
        Layout.columnSpan: 2
    }

    // Third row
    Slider {
        id: osc_1_volume

        // If saveState is defined, the "value" property will be saved in state
        property bool saveState: true

        property string controllerType: "knob"
        property int controllerNumber: 0
        property bool isInteger: false

        from: 0.0
        to: 16.0
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2(this, value);
        }
    }

    StackLayout {
        id: osc_1_waveform
        property bool saveState: true
        property alias value: osc_1_waveform.currentIndex

        property string controllerType: "knob"
        property int controllerNumber: 1
        property int from: 0
        property int to: rep.count
        property bool isInteger: true

        Layout.fillHeight: true
        Layout.maximumWidth: 64
        Repeater {
            id: rep
            model: waveEnum
            Text {
                text: modelData
            }
        }

        onCurrentIndexChanged: {
            _setLV2(this, currentIndex / (rep.count - 1));
        }
    }

    Dial {
        id: osc_1_tune
        property bool saveState: true
        from: -48
        to: 48
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 2
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }
    }

    Dial {
        id: osc_1_transpose
        property bool saveState: true
        from: -100
        to: 100
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 3
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }
    }
    
    Dial {
        id: osc_1_unison_voices
        property bool saveState: true
        from: 1
        to: 15
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 4
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }
    }

    Dial {
        id: osc_1_unison_detune
        property bool saveState: true
        from: 1
        to: 15
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 5
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }
    }

    // Associates a controller number to an Item
    property var knobToItem : ({})

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
            infoScreen.text = "Helm";

            // Set controller options
            // Also define a mapping between controller and Items
            for (var i = 0; i < root.children.length; i++) {
                let child = root.children[i];
                if (child.controllerType === "knob") {
                    if (child.controllerNumber == undefined) {
                        console.log("Missing controllerNumber, object id", MyUtils.objectId(child));
                    }
                    else {
                        knobToItem[child.controllerNumber] = child;

                        if ((child.from != undefined) && (child.to != undefined)) {
                            board.setKnobMinMax(child.controllerNumber, child.from, child.to);
                        }
                        if (child.isInteger != undefined) {
                            board.setKnobIsInteger(child.controllerNumber, child.isInteger);
                        }
                        board.setKnobValue(child.controllerNumber, child.value);
                    }
                }
            }
        }
    }

    Connections {
        target: board

        // only visible panels should react to knob / pad changes
        enabled: root.visible

        onKnobMoved : {
            if (knobNumber in knobToItem) {
                knobToItem[knobNumber].value = amount;
            }
        }
    }
}


