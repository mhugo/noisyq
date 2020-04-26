import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "utils.js" as Utils

ColumnLayout {
    id: root
    width: 68*8

    function quit()
    {
        Utils.saveFile("state.json", canvas.saveState());
        Qt.callLater(Qt.quit);
    }

    Component.onCompleted: {
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
            property var knobValue: [0, 0, 0, 0, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, 0, 0]

            // debug display
            text: "Knob " + selectedKnob + ": " + knobValue[selectedKnob]
            font.family: titleFont.name
            font.pointSize: 14
            focus: true

            Keys.onPressed : {
                // FIXME isAutoRepeat only for pads, not for knobs +/-
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
                else if (event.key == Qt.Key_Up) {
                    value = knobValue[selectedKnob] + 0.1;
                    if (value >= 1.0)
                        value = 1.0;
                    knobMoved(selectedKnob, value);
                    knobValue[selectedKnob] = value;
                }
                else if (event.key == Qt.Key_Down) {
                    value = knobValue[selectedKnob] - 0.1;
                    if (value < 0.0)
                        value = 0.0;
                    knobMoved(selectedKnob, value);
                    knobValue[selectedKnob] = value;
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

    Component {
        id: helmControls

        RowLayout {
            function saveState() {
                return {
                    "pluginName": "helm",
                    "knobs" : [dial1.value, dial2.value]
                };
            }

            function loadState(state) {
                dial1.value = state["knobs"][0];
                dial2.value = state["knobs"][1];
            }

            Dial {
                id: dial1
                Layout.maximumWidth: 64
                Layout.maximumHeight: 64
            }
            Dial {
                id: dial2
                Layout.maximumWidth: 64
                Layout.maximumHeight: 64
            }
            onVisibleChanged : {
                if (visible) {
                    padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
                }
            }
        }
    }

    Rectangle {
        id: infoScreen
        color: "#444444"
        width: parent.width
        height: 40

        Text {
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
                    instrStates.push(state);
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
                if (instrState && instrState["pluginName"] == "helm") {
                    let obj = helmControls.createObject(root, {});
                    obj.loadState(instrState);
                    assignInstrument(obj);
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
        function assignInstrument(obj) {
            children.push(obj);
            instruments[currentInstrument] = obj;
            instrumentStackIndex[currentInstrument] = children.length - 1;
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
                model: ["None", "Helm", "SamplV1"]
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
                        if (instrCombo.currentIndex == 1) {
                            let obj = helmControls.createObject(root, {});
                            canvas.assignInstrument(obj);
                            canvas.currentIndex = canvas.children.length - 1;
                        }
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
                color: "white"
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
            padRep.itemAt(padNumber).color = "white";
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
        },
        State {
            name: "projectMenu"
            PropertyChanges {
                target: padMenu
                texts: ["", "", "", "", "", "", "", "Back"]
            }
        },
        State {
            name: "instrMenu"
            PropertyChanges {
                target: padMenu
                texts: ["0", "1", "2", "3", "4", "5", "6", "Back"]
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
}
