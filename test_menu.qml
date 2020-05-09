import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "utils.js" as Utils

// TODO

ColumnLayout {
    id: root
    width: 68*8

    function quit()
    {
        Utils.saveFile("state.json", canvas.saveState());
        Qt.callLater(Qt.quit);
    }

    // List of {"name": "xxx", "lv2Url": "xxx", "component": Component}
    property var instrumentComponents : []

    Component.onCompleted: {
        // TODO load stub for lv2Host if run from qmlscene
        // use JS Object.defineProperty to add it to the "root" object ?
        console.log("____qt", Qt.application.displayName);
        // load instruments
        let instruments = Utils.readFile("instruments/instruments.json");
        if (instruments) {
            for (var i in instruments) {
                let qmlFile = "instruments/" + instruments[i]["qml"];
                let comp = Qt.createComponent(qmlFile);
                if (comp.status == Component.Ready) {
                    let url = instruments[i]["url"];
                    console.log("== Loading component for LV2 " + url + " from " + qmlFile);
                    instrumentComponents.push({
                        "name": instruments[i]["name"],
                        "lv2Url": instruments[i]["url"],
                        "component": comp
                    });
                }
                else if (comp.status == Component.Error) {
                    console.log("## Error loading " + qmlFile);
                    console.log(comp.errorString());
                }
            }
        }

        let state = Utils.readFile("state.json");
        if (state) {
            console.log("-- Loading state from state.json --");
            canvas.loadState(state);
        }
    }

    FontLoader {
        id: titleFont
        source: "fonts/big_noodle_titling.ttf"
    }
    FontLoader {
        id: pixelFont
        source: "fonts/Pixeled.ttf"
    }
    RowLayout {
        // simulate knobs and pads activations
        Text {
            id: board

            signal padPressed(int padNumber)
            signal padReleased(int padNumber)
            signal knobMoved(int knobNumber, real amount)

            property int selectedKnob : 0

            Repeater {
                id: knobs
                model: 16
                Item {
                    property real value: 0
                    property bool isInteger: false
                    property real min: 0.0
                    property real max: 1.0

                    function increment() {
                        value = value + (isInteger ? 1 : (max - min) / 10.0);
                        if (value > max) {
                            value = max;
                        }
                    }
                    function decrement() {
                        value = value - (isInteger ? 1 : (max - min) / 10.0);
                        if (value < min) {
                            value = min;
                        }
                    }
                }
            }

            Repeater {
                id: pads
                model: 8
                Item {
                    property string color: "white"
                }
            }

            function knobValue(knobNumber) {
                console.log("knobValue", knobs, knobs.count);
                return knobs.itemAt(knobNumber).value;
            }

            function setKnobValue(knobNumber, value) {
                knobs.itemAt(knobNumber).value = value;
                // manually trigger the change signal
                // since modification of only one term of an array
                // does not trigger it
                //knobValueChanged(knobValue);
            }

            function setKnobMinMax(knobNumber, min, max) {
                console.log("min max", knobNumber, min, max);
                knobs.itemAt(knobNumber).min = min;
                knobs.itemAt(knobNumber).max = max;
            }

            function setKnobIsInteger(knobNumber, isInteger) {
                knobs.itemAt(knobNumber).isInteger = isInteger;
            }

            function padColor(padNumber) {
                let item = pads.itemAt(padNumber);
                if (item === null)
                    return "white";
                return item.color;
            }
            function setPadColor(padNumber, color) {
                pads.itemAt(padNumber).color = color;
            }

            // debug display
            text: "Knob " + selectedKnob + ": " + knobValue(selectedKnob).toFixed(2)
            font.family: titleFont.name
            font.pointSize: 14
            focus: true

            Keys.onPressed : {
                if (event.key == Qt.Key_Up) {
                    knobs.itemAt(selectedKnob).increment();
                    knobMoved(selectedKnob, knobs.itemAt(selectedKnob).value);
                }
                if (event.key == Qt.Key_Down) {
                    knobs.itemAt(selectedKnob).decrement();
                    knobMoved(selectedKnob, knobs.itemAt(selectedKnob).value);
                }

                // isAutoRepeat only for pads, not for knobs +/-
                if (event.isAutoRepeat) {
                    return;
                }
                console.log(event.nativeScanCode, event.key);
                let value;
                // azerty
                if (event.nativeScanCode >= 24 && event.nativeScanCode < 32) {
                    selectedKnob = event.nativeScanCode - 24;
                }
                // wxcvbn row
                else if (event.nativeScanCode >= 52 && event.nativeScanCode < 60) {
                    let padNumber = event.nativeScanCode - 52;
                    padPressed(padNumber);
                }
                else if (event.key == Qt.Key_Escape) {
                    // escape
                    quit();
                }
            }
            Keys.onReleased : {
                if (event.isAutoRepeat) {
                    return;
                }
                // wxcvbn row
                if (event.nativeScanCode >= 52 && event.nativeScanCode < 60) {
                    let padNumber = event.nativeScanCode - 52;
                    padReleased(padNumber);
                }
            }
        }
    }

    /*QtObject {
        id: lv2Host

        // returns an lv2Id
        function addInstance(lv2Name) {
            console.log("== addInstance", lv2Name);
            return 0;
        }

        function getParameterValue(lv2Id, parameterName) {
            console.log("== getParameterValue", lv2Id, parameterName);
        }

        function setParameterValue(lv2Id, parameterName, value) {
            console.log("== setParameterValue", lv2Id, parameterName, value);
        }

        function sendMidiMessage(lv2Id, msg) {
            console.log("== sendMidiMessage", lv2id, msg);
        }
    }*/

    Rectangle {
        id: infoScreen
        color: "#444444"
        width: parent.width
        height: 40

        property alias text: text.text

        Text {
            id: text
            anchors.fill: infoScreen
            font.family: pixelFont.name
            font.pointSize: 8
            color: "white"
            text: "Display"
            verticalAlignment: Text.AlignVCenter
        }
    }

    StackLayout {
        id: canvas
        width: parent.width
        height: 64*3

        function saveState() {
            // save the state of each instrument
            var instrStates = []
            for (var i = 0; i < instruments.length; i++) {
                if (instruments[i]) {
                    let state = instruments[i].saveState();
                    instrStates.push({
                        "name": instruments[i].name,
                        "state": state
                    });
                }
                else {
                    instrStates.push(null);
                }
            }
            return {
                "instruments": instrStates,
                "stackMapping": instrumentStackIndex
            };
        }

        function loadState(state) {
            //
            instrumentStackIndex = state["stackMapping"];

            // invert the mapping instrument -> stack index
            // to get a mapping stack index -> instrument
            let stackInstrumentIndex = {};
            for (var instr in instrumentStackIndex) {
                let idx = instrumentStackIndex[instr];
                stackInstrumentIndex[idx] = instr;
            }

            for (var i in stackInstrumentIndex) {
                currentInstrument = stackInstrumentIndex[i];
                let instrState = state["instruments"][currentInstrument];
                if (instrState) {
                    let obj = assignInstrument(instrState["name"]);
                    obj.loadState(instrState["state"]);
                }
            }
        }

        // Items associated to each instrument
        property var instruments : [null, null, null, null, null, null, null]

        property int currentInstrument: 0

        // map of instrument number -> stack layout index
        property var instrumentStackIndex : ({})

        function editInstrument() {
            // display the component associated with the instrument in the canvas
            if (instruments[currentInstrument] === null) {
                // blank instrument
                currentIndex = 1;
            }
            else {
                currentIndex = instrumentStackIndex[currentInstrument];
            }
        }

        // Assign a given Item to the current instrument slot
        function assignInstrument(name) {
            // look for the instrument in the component list
            let obj = null;
            for (var i in instrumentComponents) {
                if (instrumentComponents[i].name == name) {
                    obj = instrumentComponents[i].component.createObject(root, {});
                    let lv2Id = lv2Host.addInstance(instrumentComponents[i].lv2Url);
                    obj.lv2Id = lv2Id;
                    obj.init();
                    console.log("lv2id", obj.lv2Id);
                    break;
                }
            }
            if (obj != null) {
                children.push(obj);
                instruments[currentInstrument] = obj;
                instrumentStackIndex[currentInstrument] = children.length - 1;
            }
            else {
                console.log("Cannot find instrument", name);
            }
            return obj;
        }

        // index: 0 - blank
        Text {
        }
        // index: 1 - no instrument assigned
        ColumnLayout {
            id: blankTrack
            Text {
                text: "No instrument assigned"
            }
            ComboBox {
                id: instrCombo
                Component.onCompleted : {
                    model = instrumentComponents.map(function(x) { return x["name"]; });
                }
            }
            // FIXME
            // knob values must be independant and then saved for each panel
            Connections {
                target: board

                // only visible panels should react to knob / pad changes
                enabled: blankTrack.visible

                onKnobMoved : {
                    if (knobNumber == 0) {
                        instrCombo.currentIndex = ~~(amount * (instrCombo.count-1));
                    }
                }

                onPadPressed : {
                    if (padNumber == 0) {
                        // confirm assignment
                        canvas.assignInstrument(instrCombo.currentText);
                        canvas.currentIndex = canvas.children.length - 1;
                    }
                }
            }

            onVisibleChanged : {
                if (visible) {
                    padMenu.texts = ["Assign"].concat(padMenu.texts.slice(1));
                }
            }
        }
    }

    RowLayout {
        id: padMenu
        property alias texts: padRep.model
        Repeater {
            id: padRep
            model: ["", "", "", "", "", "", "", ""]
            Pad {
                color: board.padColor(index)
                Text {
                    width: parent.width
                    height: parent.height
                    text: modelData
                    font.family: titleFont.name
                    font.pointSize: 14
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    state: "rootMenu"

    Connections {
        target: board
        onPadPressed : {
            padRep.itemAt(padNumber).color = "red";
        }
        onPadReleased : {
            padRep.itemAt(padNumber).color = board.padColor(padNumber);
            switch (state) {
            case "rootMenu": {
                switch (padNumber) {
                case 0:
                    state = "projectMenu";
                    break;
                case 1:
                    state = "instrMenu";
                    break;
                }
            }
                break;
            case "projectMenu": {
                if (padNumber == 7) {
                    state = "rootMenu";
                }
            }
                break;
            case "instrMenu": {
                if (padNumber == 7) {
                    state = "rootMenu";
                }
                else {
                    state = "instrEditMenu";
                    canvas.currentInstrument = padNumber;
                    canvas.editInstrument();
                }
            }
                break;
            case "instrEditMenu": {
                if (padNumber == 7) {
                    state = "instrMenu";
                    canvas.currentIndex = 0;
                }
            }
                break;
            }

            /*for (var i = 0; i < 8; i++) {
                padRep.itemAt(i).color = board.padColor(i);
            }*/
        }
    }

    states : [
        State {
            name: "rootMenu"
            PropertyChanges {
                target: padMenu
                texts: ["Project", "Instr.", "", "", "", "", "", ""]
            }
            PropertyChanges {
                target: canvas
                currentIndex: 0
            }
            PropertyChanges {
                target: infoScreen
                text: "Main menu"
            }
        },
        State {
            name: "projectMenu"
            PropertyChanges {
                target: padMenu
                texts: ["", "", "", "", "", "", "", "Back"]
            }
            PropertyChanges {
                target: infoScreen
                text: "Project"
            }
        },
        State {
            name: "instrMenu"
            PropertyChanges {
                target: padMenu
                texts: ["0", "1", "2", "3", "4", "5", "6", "Back"]
            }
            PropertyChanges {
                target: infoScreen
                text: "Instrument"
            }
        },
        State {
            name: "instrEditMenu"
            PropertyChanges {
                target: padMenu
                texts: ["", "", "", "", "", "", "", "Back"]
            }
        }
    ]

    onStateChanged : {
        if (state == "instrMenu") {
            // green = an instrument is assigned, white otherwise
            for (var i=0; i < 7; i++) {
                board.setPadColor(i, canvas.instruments[i] != null ? "green" : "white");
            }
        }
    }
}
