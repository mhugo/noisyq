import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

import "../../instruments/common" as Common

Item {
    id: root

    // Set by the host when the instance is created
    property string lv2Id: ""

    signal quit()

    property string name: "Piano"

    // Set by the host
    property int unitSize: 100

    readonly property int legendSize: 0.3 * unitSize

    implicitWidth: unitSize * 8
    implicitHeight: unitSize * 2 + legendSize * 2

    function saveState() {
        return {}
    }

    function loadState(state) {
    }

    property int programIndex: 0
    ListModel {
        id: programsModel
        ListElement {
            name: "Test"
            index: 0
            bank: 0
            program: 0
        }
    }

    Common.PlacedKnobMapping {
        id: idKnob
        mapping.knobNumber: 0
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        Common.FramedText {
            id: idText
            legend: "ID"
            text: parent.value
        }

        onValueChanged: {
            lv2Host.set_program(lv2Id, value);
            updatePresetControls(value);
        }
    }

    Common.PlacedKnobMapping {
        id: bankKnob
        mapping.knobNumber: 1
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        Common.FramedText {
            id: bankText
            legend: "Bank"
            text: ""
        }

        onValueChanged: {
            let id = programMap[value].programs[0].id;
            lv2Host.set_program(lv2Id, id);
            updatePresetControls(id);
        }
    }

    Common.PlacedKnobMapping {
        id: programKnob
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        Common.FramedText {
            id: programText
            legend: "Program"
            text: ""
        }

        onValueChanged: {
            let id = programMap[bankKnob.value].programs[value].id;
            lv2Host.set_program(lv2Id, id);
            updatePresetControls(id);
        }
    }

    Text {
        x: unitSize * 3
        Rectangle {
            width: unitSize * 4.9
            height: unitSize * 0.9
            x: unitSize * 0.05
            y: unitSize * 0.05
            border.color: "black"
            border.width: 3
            radius: unitSize / 10
            Text {
                id: nameText
                text: ""
                font.pixelSize: unitSize / 3
                font.family: monoFont.name
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
            }
        }
    }

    // FIXME change KnobMapping so that
    // - updating value calls setKnobValue
    // - updating min or max calls setKnobMinMax, etc. ?
    function updatePresetControls(idx) {
        idKnob.mapping.value = idx;
        board.setKnobValue(idKnob.mapping.knobNumber, idx);
        let p = programsModel.get(idx);
        let bankIdx = -1;
        for (var i = 0; i < programMap.length; i++) {
            if (programMap[i].bank === p.bank) {
                bankIdx = i;
                break;
            }
        }
        bankKnob.value = bankIdx;
        board.setKnobValue(bankKnob.mapping.knobNumber, bankIdx);
        bankText.text = p.bank;
        
        let programIdx = -1;
        for (var j = 0; j < programMap.length; j++) {
            if (programMap[bankIdx].programs[j].program === p.program) {
                programIdx = j;
                break;
            }
        }
        programKnob.value = programIdx;
        board.setKnobValue(programKnob.mapping.knobNumber, programIdx);
        programKnob.mapping.max = programMap[bankIdx].programs.length - 1;
        board.setKnobMinMax(programKnob.mapping.knobNumber, 0, programMap[bankIdx].programs.length - 1);
        programText.text = p.program;

        nameText.text = p.name;
    }

    // bank id -> program id -> id
    // e.g. [{"bank": 0, "programs": [{"program": 34, "id": 0}, {"program": 45, "id": 1}]}]
    property var programMap: []

    // Initialize a state, reading from the living LV2 process
    function init() {
        lv2Host.set_program(lv2Id, 0);

        let programs = lv2Host.programs(lv2Id);
        programsModel.clear();
        idKnob.mapping.max = programs.length - 1;
        board.setKnobMinMax(idKnob.mapping.knobNumber, 0, programs.length - 1);
        for (var i = 0; i < programs.length; i++) {
            let program = programs[i];
            let bank = program["bank"];
            let bankIdx = -1;
            for (var j = 0; j < programMap.length; j++) {
                if (programMap[j].bank === bank) {
                    bankIdx = j;
                    break;
                }
            }
            if (bankIdx === -1) {
                programMap.push({"bank": bank, "programs": []});
                bankIdx = programMap.length - 1;
            }

            programMap[bankIdx].programs.push({"program": program["program"], "id": i});

            programsModel.append({"index": i, "name": program["name"], "bank": program["bank"], "program": program["program"]});
        }
        bankKnob.mapping.max = programMap.length - 1;
        board.setKnobMinMax(bankKnob.mapping.knobNumber, 0, programMap.length - 1);

        updatePresetControls(0);
    }
}
