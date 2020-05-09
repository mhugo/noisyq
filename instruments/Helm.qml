import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

// TODO
// - better alignment of widgets
// - widgets: text rather than knobs for most integer parameters (tune, transpose, etc.)
// - widgets: factorization
// - handle "cross modulation" on knob8 + shift
// - add other tabs (enveloppes, etc.)
// - handle modulation

GridLayout {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://tytel.org/helm"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Helm"

    // shortcut
    function _setLV2(obj, value) {
        lv2Host.setParameterValue(lv2Id, Utils.objectId(obj), value);
    }

    // Automatically save values of objects with "saveState" property defined
    // Use its id as parameter name
    function saveState() {
        let d = {};
        for (var i = 0; i < root.data.length; i++) {
            let child = root.data[i];
            if (child.saveState != undefined) {
                let id = Utils.objectId(child);
                d[id] = child.value;
            }
        }
        return d;
    }

    function loadState(state) {
        console.log("loadState", state);
        for (var i = 0; i < root.data.length; i++) {
            let child = root.data[i];
            if (child.saveState != undefined) {
                let id = Utils.objectId(child);
                if (id in state) {
                    child.value = state[id];
                }
            }
        }
    }

    // Initialize a state, reading from the living LV2 process
    function init() {
        console.log("init");
        for (var i = 0; i < root.data.length; i++) {
            let child = root.data[i];
            if (child.saveState != undefined) {
                let parameterName = Utils.objectId(child);
                console.log("---", parameterName);
                console.log("--- child", child);
                child.setFromLV2(lv2Host.getParameterValue(lv2Id, parameterName));
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
        Layout.columnSpan: 6
        Layout.fillWidth: true
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: "black"
        }
        Text {
            text: "[ OSC 1 ]"
        }
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: "black"
        }
    }

    Text {
        Layout.columnSpan: 2
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
        text: "Sub. vol."
    }
    Text {
        text: "Noise vol."
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

        function setFromLV2(v) {
            value = v * (to - from) + from;
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

        function setFromLV2(v) {
            value = ~~(v * (to - from) + from);
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

        function setFromLV2(v) {
            value = v * (to - from) + from;
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

        function setFromLV2(v) {
            value = v * (to - from) + from;
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

        function setFromLV2(v) {
            value = v * (to - from) + from;
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

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Slider {
        id: sub_volume

        property bool saveState: true

        property string controllerType: "knob"
        property int controllerNumber: 6
        property bool isInteger: false

        from: 0.0
        to: 16.0
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2(this, value);
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Slider {
        id: noise_volume

        property bool saveState: true

        property string controllerType: "knob"
        property int controllerNumber: 7
        property bool isInteger: false

        from: 0.0
        to: 16.0
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2(this, value);
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }
    
    // Fifth row

    Slider {
        id: osc_2_volume

        // If saveState is defined, the "value" property will be saved in state
        property bool saveState: true

        property string controllerType: "knob"
        property int controllerNumber: 8
        property bool isInteger: false

        from: 0.0
        to: 16.0
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2(this, value);
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    StackLayout {
        id: osc_2_waveform
        property bool saveState: true
        property alias value: osc_2_waveform.currentIndex

        property string controllerType: "knob"
        property int controllerNumber: 9
        property int from: 0
        property int to: rep.count
        property bool isInteger: true

        Layout.fillHeight: true
        Layout.maximumWidth: 64
        Repeater {
            id: rep2
            model: waveEnum
            Text {
                text: modelData
            }
        }

        onCurrentIndexChanged: {
            _setLV2(this, currentIndex / (rep2.count - 1));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Dial {
        id: osc_2_tune
        property bool saveState: true
        from: -48
        to: 48
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 10
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Dial {
        id: osc_2_transpose
        property bool saveState: true
        from: -100
        to: 100
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 11
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }
    
    Dial {
        id: osc_2_unison_voices
        property bool saveState: true
        from: 1
        to: 15
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 12
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Dial {
        id: osc_2_unison_detune
        property bool saveState: true
        from: 1
        to: 15
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 13
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    StackLayout {
        id: sub_waveform
        property bool saveState: true
        property alias value: sub_waveform.currentIndex

        property string controllerType: "knob"
        property int controllerNumber: 14
        property int from: 0
        property int to: rep.count
        property bool isInteger: true

        Layout.fillHeight: true
        Layout.maximumWidth: 64
        Repeater {
            id: rep3
            model: waveEnum
            Text {
                text: modelData
            }
        }

        onCurrentIndexChanged: {
            _setLV2(this, currentIndex / (rep3.count - 1));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    Dial {
        id: sub_shuffle
        property bool saveState: true
        from: 0
        to: 100
        Layout.maximumHeight: 64
        Layout.maximumWidth: 64

        property string controllerType: "knob"
        property int controllerNumber: 15
        property bool isInteger: true

        onValueChanged: {
            _setLV2(this, (value - from) / (to - from));
        }

        function setFromLV2(v) {
            value = v * (to - from) + from;
        }
    }

    // Text of second knob row

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
        text: "Sub. shape."
    }
    Text {
        text: "Sub. shuffle."
    }

    
    RowLayout {
        Layout.columnSpan: 6
        Layout.fillWidth: true
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: "black"
        }
        Text {
            text: "[ OSC 2 ]"
        }
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: "black"
        }
    }

    Text {
        Layout.columnSpan: 2
    }

    QtObject {
        id: unison_1_harmonize
        property bool saveState: true
        property string controllerType: "pad"
        property int controllerNumber: 5

        property bool value: false

        onValueChanged: {
            _setLV2(this, value ? 1.0 : 0.0);
        }

        function setFromLV2(v) {
            value = v;
        }
    }

    QtObject {
        id: unison_2_harmonize
        property bool saveState: true
        property string controllerType: "pad"
        property int controllerNumber: 6

        property bool value: false

        onValueChanged: {
            _setLV2(this, value ? 1.0 : 0.0);
        }

        function setFromLV2(v) {
            value = v;
        }
    }

    // Associates a controller number to an Item
    property var knobToItem : ({})
    property var padToItem : ({})

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Osc", "", "", "", "", "Osc 1 H", "Osc 2 H", "Back"];
            infoScreen.text = "Helm";

            // Set controller options
            // Also define a mapping between controller and Items
            for (var i = 0; i < root.data.length; i++) {
                let child = root.data[i];
                if (child.controllerType === "knob") {
                    if (child.controllerNumber == undefined) {
                        console.log("Missing controllerNumber, object id", Utils.objectId(child));
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
                else if (child.controllerType === "pad") {
                    console.log("child pad", child);
                    if (child.controllerNumber == undefined) {
                        console.log("Missing controllerNumber, object id", Utils.objectId(child));
                    }
                    else {
                        padToItem[child.controllerNumber] = child;
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

        onPadPressed: {
            if (padNumber in padToItem) {
                padToItem[padNumber].value = ! padToItem[padNumber].value;
                console.log("pad", padNumber, padToItem[padNumber].value);
                board.setPadColor(padNumber, padToItem[padNumber].value ? "red" : "white");
            }
        }
    }
}


