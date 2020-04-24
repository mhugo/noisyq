import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    id: root
    width: 68*8
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

            text: "Knob " + selectedKnob + ": " + knobValue[selectedKnob]
            font.family: titleFont.name
            font.pointSize: 14
            focus: true

            Keys.onPressed : {
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
                    Qt.quit();
                }
                else if (event.key == Qt.Key_Up) {
                    value = knobValue[selectedKnob] + 0.1;
                    if (value >= 1.0)
                        value = 1.0;
                    knobMoved(selectedKnob, value);
                    knobValue[selectedKnob] = value;
                    console.log("up ", value);
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
        Text {
        }
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
                    console.log("on knob moved");
                    if (knobNumber == 0) {
                        instrCombo.currentIndex = ~~(amount * (instrCombo.count-1));
                    }
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

    property var instruments : [null, null, null, null, null, null, null]

    function editInstrument(instrNumber) {
        // display the component associated with the instrument in the canvas
        if (instruments[instrNumber] === null) {
            // blank instrument
            canvas.currentIndex = 1;
            padMenu.texts = ["Assign"].concat(padMenu.texts.slice(1));
        }
    }

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
                    editInstrument(padNumber);
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
