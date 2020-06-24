import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

import Qt.labs.folderlistmodel 2.11

Item {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://samplv1.sourceforge.net/lv2"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Samplv1"

    // Set by the host
    property int unitSize: 100

    implicitWidth: unitSize * 8
    implicitHeight: unitSize * 2

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
        _loadSample(state.sampleFileName);
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
        console.log("samplv1 init");
        // enable offseting
        lv2Host.setParameterValue(lv2Id, "GEN1_OFFSET", 1.0);

        board.setKnobMinMax(0, 0.0, 1.0);
        board.setKnobIsInteger(0, false);
        board.setKnobValue(0, 0);

        board.setKnobMinMax(1, 0.0, 1.0);
        board.setKnobIsInteger(1, false);
        board.setKnobValue(1, 1.0);
    }

    Item {
        id: debug_grid
        Repeater {
            model: 8
            Rectangle {
                x: index * root.unitSize
                y: 0
                width: root.unitSize
                height: root.unitSize
                border.color: "red"
                border.width: 1
            }
        }
        Repeater {
            model: 8
            Rectangle {
                x: index * root.unitSize
                y: root.unitSize
                width: root.unitSize
                height: root.unitSize
                border.color: "red"
                border.width: 1
            }
        }

        Rectangle {
            border.width: 1
            border.color: "black"
            width: root.unitSize * 4
            height: root.unitSize
        }
    }

    Item {
        id: waveform
        x: 0
        y: 0
        
        Item {
            // waveform plot + legends

            Image {
                id: waveformImage
                x: 0
                y: 0

                // range before offset start
                Rectangle {
                    width: offsetStart.value * parent.width
                    border.width: 1
                    border.color: "red"
                    height: parent.height
                    y: 0
                    z: 1
                    x: 0
                    color: "grey"
                    opacity: 0.5
                }
                // range after offset end
                Rectangle {
                    width: (1.0 - offsetEnd.value) * parent.width
                    border.width: 1
                    border.color: "red"
                    height: parent.height
                    y: 0
                    z: 1
                    x: offsetEnd.value * parent.width
                    color: "grey"
                    opacity: 0.5
                }
                // loop range
                Rectangle {
                    width: (loopEnd.value - loopStart.value) * parent.width
                    height: parent.height
                    y: 0
                    z: 1
                    x: loopStart.value * parent.width
                    color: "yellow"
                    opacity: 0.5
                    visible: loopEnabled.value
                }
            }

            Text {
                text: {
                    if (sampleFileName) {
                        let splitFileName = sampleFileName.split("/");
                        return splitFileName[splitFileName.length - 1];
                    }
                    return "<None>";
                }
                x: 0
                y: 0
            }

            KnobMapping {
                id: offsetStart
                x: 0
                y: 0

                // between 0 and 1
                value: 0

                knobNumber: 0
                parameterName: "GEN1_OFFSET_1"
                parameterDisplay: "Offset start"
                function valueToString(v) {
                    return ~~(v * 100) + "%"
                }

                onValueChanged: {
                    if (loopStart.value < offsetStart.value)
                        loopStart.value = offsetStart.value;
                    // restrict offset end and loop end
                    board.setKnobMinMax(1, offsetStart.value, 1.0);
                    board.setKnobMinMax(2, offsetStart.value, loopEnd.value);
                    board.setKnobValue(2, loopStart.value);
                }

                Text {
                    text: "Start"
                    x : (root.unitSize - width) / 2
                    y : root.unitSize - height
                }
            }

            KnobMapping {
                id: offsetEnd
                x: root.unitSize
                y: 0
                // between 0 and 1
                value: 1.0

                knobNumber: 1
                parameterName: "GEN1_OFFSET_2"
                parameterDisplay: "Offset end"
                function valueToString(v) {
                    return ~~(v * 100) + "%"
                }

                onValueChanged: {
                    // offset end
                    if (loopEnd.value > offsetEnd.value)
                        loopEnd.value = offsetEnd.value;
                    // restrict offset start and loop start
                    board.setKnobMinMax(0, 0.0, offsetEnd.value);
                    board.setKnobMinMax(3, loopStart.value, offsetEnd.value);
                    board.setKnobValue(3, loopEnd.value);
                }

                Text {
                    text: "End"
                    x : (root.unitSize - width) / 2
                    y : root.unitSize - height
                }
            }

            KnobMapping {
                id: loopStart
                x: 2 * root.unitSize
                y: 0
                // between 0 and 1
                value: 0
                parameterName: "GEN1_LOOP_1"
                parameterDisplay: "Loop start"
                knobNumber: 2
                function valueToString(v) {
                    return ~~(v * 100) + "%"
                }

                Text {
                    text: "Loop start"
                    x : (root.unitSize - width) / 2
                    y : root.unitSize - height
                    color: loopEnabled.value ? "black" : "grey"
                }
            }

            KnobMapping {
                id: loopEnd
                x: 3 * root.unitSize
                y: 0
                // between 0 and 1
                value: 1.0

                parameterName: "GEN1_LOOP_2"
                parameterDisplay: "Loop end"
                knobNumber: 3
                function valueToString(v) {
                    return ~~(v * 100) + "%"
                }

                Text {
                    text: "Loop end"
                    x : (root.unitSize - width) / 2
                    y : root.unitSize - height
                    color: loopEnabled.value ? "black" : "grey"
                }
            }
        }

        ListView { // sample file selection
            id: sampleFileList
            visible: false
            width: root.unitSize * 4
            height: root.unitSize
            clip: true
            x: 0
            y: 0
            Rectangle {
                anchors.fill: parent
                z: -1
            }
            model: FolderListModel {
                rootFolder: "/home/hme/perso/music/samples"
                folder: "/home/hme/perso/music/samples"
                nameFilters: ["*.wav", "*.aif", "*.flac"]
                showDirsFirst: true
                showDotAndDotDot: true

                onStatusChanged: {
                    if (sampleFileList.visible && (status == FolderListModel.Ready)) {
                        board.setKnobMinMax(0, 0, sampleFileList.count - 1);
                        board.setKnobValue(0, 0);
                    }
                }
            }
            delegate : RowLayout {
                width: sampleFileList.width
                Text {
                    text: fileIsDir ? "D" : "F"
                }
                Text {
                    elide: Text.ElideMiddle
                    // width does not work with RowLayout
                    Layout.preferredWidth: parent.width * 0.8
                    text: fileName
                }
                Item {
                    Layout.fillWidth:true
                }
                Text {
                    text: fileIsDir ? "" : ~~(fileSize / 1024) + "kB"
                }
            }
            highlight: Rectangle {
                border.color: "red"
                border.width: 1
            }
            currentIndex: 0

            onVisibleChanged : {
                if (visible) {
                    board.setKnobMinMax(0, 0, sampleFileList.count - 1);
                    board.setKnobIsInteger(0, true);
                    board.setKnobValue(0, 0);
                }
            }

        }

        // The knob 1 switch is used both to select a file (i.e. show the file list)
        // and to confirm a file selection (i.e. show back the waveform plot)
        Connections {
            target: board
            enabled: waveform.visible
            onKnobMoved : {
                if (knobNumber==0 && waveform.children[1].visible) {
                    // move file selection list
                    sampleFileList.currentIndex = amount;
                }
            }
            onPadReleased: {
                if (padNumber==16) {
                    // knob1 switch
                    if (waveform.children[0].visible) { // the waveform plot is visible
                        // the list is not visible yet, make it visible
                        waveform.children[0].visible = false;
                        waveform.children[1].visible = true;
                    }
                    else { // the list is visible
                        // we load a file / enter a directory
                        if (_acceptListEntry()) {
                            // done
                            waveform.children[1].visible = false;
                            waveform.children[0].visible = true;
                        }
                    }
                }
            }
        }
    }

    PadSwitchMapping {
        id: loopEnabled
        x: root.unitSize * 2
        y: root.unitSize * 1
        padNumber: 2

        parameterName: "GEN1_LOOP"
        parameterDisplay: "Loop enabled"

        onValueChanged: {
            padMenu.updateText(2, value ? "Loop\nOn" : "Loop\nOff");
        }
    }

    PadSwitchMapping {
        id: genReverse
        padNumber: 3

        parameterName: "GEN1_REVERSE"
        parameterDisplay: "Reversed"
        onValueChanged: {
            padMenu.updateText(3, value ? "Reversed\nOn" : "Reversed\nOff");
        }
    }

    KnobMapping {
        x: 4 * root.unitSize
        y: 0

        // midi note
        value: 60

        parameterName: "GEN1_SAMPLE"
        knobNumber: 4
        isInteger: true
        min: 0
        max: 127
        function valueToString(v) {
            return Utils.midiNoteName(v);
        }

        Text {
            y: 0.3 * root.unitSize
            x: (root.unitSize - width) / 2
            font.pixelSize: 16
            font.family: monoFont.name
            text: parent.valueToString(parent.value)
        }

        Text {
            text: "Base note"
            y: root.unitSize - height
            x: (root.unitSize - width) / 2
        }
    }

    KnobMapping {
        x: 5 * root.unitSize
        y: 0

        // cents, between -1 (-100 cents) and 1 (+100 cents)
        value: 0.0

        parameterName: "GEN1_TUNING"
        knobNumber: 5
        isInteger: true
        min: -100
        max: 100
        function toParameter(v) {
            return v/100.0;
        }
        function fromParameter(v) {
            return ~~(v*100.0);
        }

        NumberFrame {
            value: ~~(parent.value * 100)
            displaySign: true
            text: "cents"
        }

        Text {
            text: "Tuning"
            y: root.unitSize - height
            x: (root.unitSize - width) / 2
        }
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = [
                "",
                "Play",
                "Loop\nOff",
                "Reversed\nOff",
                "",
                "",
                "",
                "Back"];
        }
    }

    function _loadSample(sampleFile) {
        if (!sampleFile)
            return;
        // manipulate the state in order to include the sample file
        const sample_file_key = "http://samplv1.sourceforge.net/lv2#P101_SAMPLE_FILE";
        let state_str = lv2Host.save_state(lv2Id, /* convert_xml_to_json */ true);
        
        if (state_str) {
            let state = JSON.parse(state_str);
            let children = state.children[1].children;
            for (var i=0; i < children.length; i++) {
                let child = children[i];
                if (child.tag == "CustomData") {
                    let key = child.children[1].text;
                    if (key == sample_file_key) {
                        // remove
                        children.splice(i, 1);
                        break;
                    }
                }
            }
            // add back the customdata
            children.push({
                "tag" : "CustomData",
                "children": [
                    {
                        "tag": "Type",
                        "text": "http://lv2plug.in/ns/ext/atom#Path"
                    },
                    {
                        "tag": "Key",
                        "text": sample_file_key
                    },
                    {
                        "tag": "Value",
                        "text": sampleFile
                    }
                ]});
            state_str = JSON.stringify(state);
            
            // force state update
            lv2Host.load_state(lv2Id, state_str, /*convert_json_to_xml*/ true);
        }

        // update graph
        let waveformFile = Utils.getAudioWaveformImage(sampleFile, 4*root.unitSize, unitSize);
        waveformImage.source = waveformFile;

        // update sample file name
        root.sampleFileName = sampleFile;
    }

    // if a file is selected, load it, and returns true
    // if a folder is selected, enter it, and returns false
    function _acceptListEntry() {
        // enter a directory
        if (sampleFileList.model.isFolder(sampleFileList.currentIndex)) {
            sampleFileList.model.folder += "/" + sampleFileList.model.get(sampleFileList.currentIndex, "fileName");
            sampleFileList.currentIndex = 0;
            return false;
        }
        let sampleFile = sampleFileList.model.folder + "/" + sampleFileList.model.get(sampleFileList.currentIndex, "fileName");
        // remove "file://"
        sampleFile = sampleFile.slice(7);

        _loadSample(sampleFile);

        return true;
    }

    function padPressed(padNumber) {
        if (padNumber == 1) {
            // BANG !
            lv2Host.noteOn(lv2Id, 60, 127);
        }
    }

    // will be called by main
    function padReleased(padNumber) {
        console.log("pad pressed", padNumber);
        if (padNumber == 1) {
            // BANG !
            lv2Host.noteOff(lv2Id, 60);
        }
        else if (padNumber == 7) {
            // end of editing
            canvas.endEditInstrument();
        }
    }

}
