import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

Item {
    id: root

    property string lv2Id: ""

    property bool usePresets: false

    property int voice: 0

    // current program or preset for each voice
    property var selected: ({})

    function update() {
        if (!usePresets) {
            initPrograms(lv2Id)
            idKnob.mapping.value = root.selected[voice]["id"] || 0;
        } else {
            initPresets(lv2Id)
            presetBankKnob.mapping.value = root.selected[voice]["bank"] || 0;
            presetKnob.mapping.value = root.selected[voice]["preset"] || 0;
        }
    }

    function savePreset() {
        if (!(voice in root.selected)) {
            root.selected[voice]={};
        }
        if (!usePresets) {
            root.selected[voice]["id"] = ~~(idKnob.mapping.value || 0);
        } else {
            root.selected[voice]["bank"] = ~~(presetBankKnob.mapping.value||0);
            root.selected[voice]["preset"] = ~~(presetBankKnob.mapping.value||0);
        }
    }

    readonly property int legendSize: 0.3 * unitSize

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

    PlacedKnobMapping {
        id: idKnob
        mapping.knobNumber: 0
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        FramedText {
            id: idText
            legend: "ID"
            text: parent.value
        }

        onValueChanged: {
            lv2Host.set_program(lv2Id, value);
            updateProgramControls(value);
        }

        visible: !usePresets
    }

    PlacedKnobMapping {
        id: bankKnob
        mapping.knobNumber: 1
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        FramedText {
            id: bankText
            legend: "Bank"
            text: ""
        }

        onValueChanged: {
            let id = programMap[value].programs[0].id;
            lv2Host.set_program(lv2Id, id);
            updateProgramControls(id);
        }

        visible: !usePresets
    }

    PlacedKnobMapping {
        id: programKnob
        mapping.knobNumber: 2
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        FramedText {
            id: programText
            legend: "Program"
            text: ""
        }

        onValueChanged: {
            let id = programMap[bankKnob.value].programs[value].id;
            lv2Host.set_program(lv2Id, id);
            updateProgramControls(id);
        }
        visible: !usePresets
    }

    Text {
        x: unitSize * 3
        Rectangle {
            width: unitSize * 3.9
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
        visible: !usePresets
    }

    PlacedKnobMapping {
        id: presetBankKnob
        mapping.knobNumber: 0
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        FramedText {
            id: presetBankText
            legend: "Preset bank"
            text: ""
            unitWidth: 3
        }

        onValueChanged: {
            let bankId = presetBankKnob.mapping.value;
            let presetId = presetKnob.mapping.value;
            updatePresetControls(bankId, presetId);
        }

        visible: usePresets
    }

    PlacedKnobMapping {
        id: presetKnob
        mapping.knobNumber: 3
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 0
        mapping.value: 0

        FramedText {
            id: presetText
            legend: "Preset"
            text: ""
            unitWidth: 4
        }

        onValueChanged: {
            let bankId = presetBankKnob.mapping.value;
            let presetId = presetKnob.mapping.value;
            updatePresetControls(bankId, presetId);
        }
        visible:usePresets
    }

    // FIXME change KnobMapping so that
    // - updating value calls setKnobValue
    // - updating min or max calls setKnobMinMax, etc. ?
    function updateProgramControls(idx) {
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

    function updatePresetControls(bankIdx, presetIdx) {
        presetBankKnob.mapping.value = bankIdx;
        presetBankText.text = presetMap[bankIdx].bank;

        let presets = presetMap[bankIdx].presets;
        console.log("presets len", presets.length);
        presetKnob.mapping.value = presetIdx;
        presetKnob.mapping.max = presets.length - 1;
        presetText.text = presets[presetIdx];
        board.setKnobMinMax(presetKnob.mapping.knobNumber, 0, presets.length - 1);

        lv2Host.setPreset(lv2Id, presetMap[bankIdx].bank, presets[presetIdx]);
    }

    // bank id -> program id -> id
    // e.g. [{"bank": 0, "programs": [{"program": 34, "id": 0}, {"program": 45, "id": 1}]}]
    property var programMap: []

    // preset bank -> presets
    // e.g. [{"bank": "BANK 1", "presets": ["preset1", "preset2"]}]
    property var presetMap: []

    // Initialize a state, reading from the living LV2 process
    function initPrograms() {
        lv2Host.set_program(lv2Id, 0);

        let programs = lv2Host.programs(lv2Id);
        programsModel.clear();
        idKnob.mapping.max = programs.length - 1;
        board.setKnobMinMax(idKnob.mapping.knobNumber, 0, programs.length - 1);
        console.log("//init Programs", "# programs", programs.length);
        
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
            console.log("name", program["name"]);

            programsModel.append({"index": i, "name": program["name"], "bank": program["bank"], "program": program["program"]});
        }
        bankKnob.mapping.max = programMap.length - 1;
        board.setKnobMinMax(bankKnob.mapping.knobNumber, 0, programMap.length - 1);

        updateProgramControls(0);
    }

    function initPresets()
    {
        presetMap = lv2Host.presets(lv2Id);
        presetBankKnob.mapping.max = presetMap.length - 1;
        console.log("********** init presets", "bank", presetMap.length);
        board.setKnobMinMax(presetBankKnob.mapping.knobNumber, 0, presetMap.length - 1);
        if (presetMap.length) {
            updatePresetControls(0, 0);
        }
    }
}
