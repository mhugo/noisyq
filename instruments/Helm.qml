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


StackLayout {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://tytel.org/helm"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Helm"

    property int unitSize: 100

    // shortcut
    function _setLV2(obj, value) {
        console.log("_setLV2", obj, value);
        if (lv2Id) {
            lv2Host.setParameterValue(lv2Id, Utils.objectId(obj), value);
        }
    }

    // Automatically save values of objects with "saveState" property defined
    // Use its id as parameter name
    function saveState() {
        let d = {};
        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.saveState != undefined) {
                let id = Utils.objectId(child);
                d[id] = child.value;
            }
        }
        return d;
    }

    function loadState(state) {
        console.log("loadState", state);
        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
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
        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.saveState != undefined) {
                let parameterName = Utils.objectId(child);
                console.log("---", parameterName);
                console.log("--- child", child);
                child.setFromLV2(lv2Host.getParameterValue(lv2Id, parameterName));
            }
        }

        // populate programs
        if (program_panel.programs == undefined) {
            program_panel.programs = lv2Host.programs(lv2Id);
        }
    }

    ColumnLayout {
        id: program_panel
        RowLayout {
            property string controllerType: "knob"
            property int controllerNumber: 0
            property bool isInteger: true
            property int from: 0
            property int to: 1 // will be updated
            property alias value: bank_combo.currentIndex

            Text { text: "Bank" }
            ComboBox {
                id: bank_combo
                model: []

                onCurrentIndexChanged : {
                    let bank = model[currentIndex];
                    let l = [];
                    for (var i = 0; i < program_panel.programs.length; i++) {
                        let p = program_panel.programs[i];
                        if (p.bank == bank) {
                            l.push({name: p.name, programId: i});
                        }
                    }
                    program_combo.model = l;
                    // update knob min / max for program
                    board.setKnobMinMax(8, 0, l.length-1);
                }
            }
        }
        RowLayout {
            property string controllerType: "knob"
            property int controllerNumber: 8
            property bool isInteger: true
            property int from: 0
            property int to: 1 // will be updated
            property alias value: program_combo.currentIndex

            Text { text: "Program" }
            ComboBox {
                id: program_combo
                textRole: "name"
                model: ListModel {
                    ListElement {
                        name: "test"
                        programId: 0
                    }
                }

                onCurrentIndexChanged : {
                    console.log("program id", model[currentIndex].programId);
                    lv2Host.set_program(lv2Id, model[currentIndex].programId);
                    // read back parameters from the host
                    root.init();
                }
            }
        }
        onVisibleChanged : {
            if (visible) {
                padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
            }
        }

        property var programs

        property int currentBank
        property int currentProgram
        property string currentProgramName

        onProgramsChanged : {
            let l = [];
            for (var i = 0; i < programs.length; i++) {
                let p = programs[i];
                if (l.indexOf(p.bank) == -1) {
                    l.push(p.bank);
                }
            }
            program_combo.model = [];
            bank_combo.model = l;
            // update knob min / max for bank
            board.setKnobMinMax(0, 0, l.length-1);
        }        
    }

    GridLayout {
        id: osc_panel

        columns: 8

        columnSpacing: 0

        // First row
        RowLayout {
            spacing: 0
            Layout.columnSpan: 6
            Layout.fillWidth: true
            Rectangle {
                Layout.fillWidth: true
                height: 4
                color: "#fcba03"
            }
            Text {
                text: "OSC 1"
                font.bold: true
                color: "white"
                Rectangle {
                    color: "#fcba03"
                    width: parent.width + 16
                    height: parent.height + 4
                    y: - 2
                    x: - 8
                    radius: 5
                    z: -1
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 4
                color: "#fcba03"
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
            text: "Transp."
        }

        Text {
            text: "Tune"
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
            Layout.maximumWidth: root.unitSize
            Layout.maximumHeight: root.unitSize

            implicitWidth: root.unitSize

            onValueChanged: {
                _setLV2(this, value / to);
            }

            function setFromLV2(v) {
                value = v * (to - from) + from;
            }
        }

        WaveForm {
            id: osc_1_waveform
            property bool saveState: true

            property string controllerType: "knob"
            property int controllerNumber: 1
            property bool isInteger: true
            size: main.unitSize

            onValueChanged: {
                _setLV2(this, value / (count - 1));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_1_transpose
            text: "semis"

            property bool saveState: true
            property real from: -48
            property real to: 48
            property string controllerType: "knob"
            property int controllerNumber: 2
            property bool isInteger: true
            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_1_tune
            text: "cents"

            property bool saveState: true
            property real from: -100
            property real to: 100
            property string controllerType: "knob"
            property int controllerNumber: 3
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_1_unison_voices
            property bool saveState: true
            property real from: 1
            property real to: 15

            property string controllerType: "knob"
            property int controllerNumber: 4
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }

            text: "voices"
            displaySign: false
        }

        NumberFrame {
            id: osc_1_unison_detune
            property bool saveState: true
            property real from: 0
            property real to: 100

            property string controllerType: "knob"
            property int controllerNumber: 5
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }

            text: "cents"
            displaySign: false
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
            Layout.maximumWidth: root.unitSize
            Layout.maximumHeight: root.unitSize

            onValueChanged: {
                _setLV2(this, value / to);
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
            Layout.maximumWidth: root.unitSize
            Layout.maximumHeight: root.unitSize

            onValueChanged: {
                _setLV2(this, value / to);
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
            Layout.maximumWidth: root.unitSize
            Layout.maximumHeight: root.unitSize

            onValueChanged: {
                _setLV2(this, value / to);
            }

            function setFromLV2(v) {
                value = v * (to - from) + from;
            }
        }

        WaveForm {
            id: osc_2_waveform
            property bool saveState: true

            property string controllerType: "knob"
            property int controllerNumber: 9
            property bool isInteger: true

            size: main.unitSize

            onValueChanged: {
                _setLV2(this, value / (count - 1));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_2_transpose
            text: "semis"

            property bool saveState: true
            property real from: -48
            property real to: 48
            property string controllerType: "knob"
            property int controllerNumber: 10
            property bool isInteger: true
            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_2_tune
            text: "cents"

            property bool saveState: true
            property real from: -100
            property real to: 100
            property string controllerType: "knob"
            property int controllerNumber: 11
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: osc_2_unison_voices
            property bool saveState: true
            property real from: 1
            property real to: 15

            property string controllerType: "knob"
            property int controllerNumber: 12
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }

            text: "voices"
            displaySign: false
        }

        NumberFrame {
            id: osc_2_unison_detune
            property bool saveState: true
            property real from: 0
            property real to: 100

            property string controllerType: "knob"
            property int controllerNumber: 13
            property bool isInteger: true

            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }

            text: "cents"
            displaySign: false
        }

        WaveForm {
            id: sub_waveform
            property string controllerType: "knob"
            property int controllerNumber: 14
            property bool isInteger: true

            size: main.unitSize

            onValueChanged: {
                _setLV2(this, value / (count - 1));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
            }
        }

        NumberFrame {
            id: sub_shuffle
            unit: "%"

            property bool saveState: true
            property real from: 0
            property real to: 100
            property string controllerType: "knob"
            property int controllerNumber: 15
            property bool isInteger: false
            onValueChanged: {
                _setLV2(this, (value - from) / (to - from));
            }

            function setFromLV2(v) {
                value = Math.round(v * (to - from) + from);
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
            spacing: 0
            Layout.columnSpan: 6
            Layout.fillWidth: true
            Rectangle {
                Layout.fillWidth: true
                height: 4
                color: "#fcba03"
            }
            Text {
                text: "OSC 2"
                font.bold: true
                color: "white"
                Rectangle {
                    color: "#fcba03"
                    width: parent.width + 16
                    height: parent.height + 4
                    x: - 8
                    y: - 2
                    radius: 5
                    z: -1
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 4
                color: "#fcba03"
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
        onVisibleChanged : {
            if (visible) {
                padMenu.texts = ["", "", "", "", "", "Osc 1 H", "Osc 2 H", "Back"];
            }
        }

    }

    // Associates a controller number to an Item
    property var knobToItem : ({})
    property var padToItem : ({})

    onCurrentIndexChanged : {
        // Set controller options
        // Also define a mapping between controller and Items
        knobToItem = {};
        padToItem = {};
        let children = root.children[currentIndex].data;
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
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
                if (child.controllerNumber == undefined) {
                    console.log("Missing controllerNumber, object id", Utils.objectId(child));
                }
                else {
                    padToItem[child.controllerNumber] = child;
                }
            }
        }

    }

    // will be called by main
    function knobMoved(knobNumber, amount) {
        console.log("knobNumber", knobNumber, amount);
        if (knobNumber in knobToItem) {
            console.log("in knobToItem");
            knobToItem[knobNumber].value = amount;
        }
    }

    // will be called by main
    function padReleased(padNumber) {
        if (padNumber in padToItem) {
            padToItem[padNumber].value = ! padToItem[padNumber].value;
            board.setPadColor(padNumber, padToItem[padNumber].value ? "red" : "white");
        }
        else {
            if (currentIndex == 0) {
                if (padNumber == 0) {
                    // goto osc panel
                    currentIndex = 1;
                }
                else if (padNumber == 7) {
                    // end of editing
                    canvas.endEditInstrument();
                }
            }
            else {
                // in osc panel
                if (padNumber == 7) {
                    // back to main panel
                    currentIndex = 0;
                }
            }
        }
    }
}


