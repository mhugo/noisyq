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
        return {"sampleFileName" : sampleFileName};
    }

    function loadState(state) {
        _loadSample(state.sampleFileName);
    }

    // Initialize a state, reading from the living LV2 process
    function init() {
        console.log("samplv1 init");
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

        Text {
            text: "Start"
            x : (root.unitSize - width) / 2
            y : root.unitSize - height
        }

        Text {
            text: "End"
            x : root.unitSize + (root.unitSize - width) / 2
            y : root.unitSize - height
        }

        Text {
            text: "Loop start"
            x : 2 * root.unitSize + (root.unitSize - width) / 2
            y : root.unitSize - height
        }

        Text {
            text: "Loop end"
            x : 3 * root.unitSize + (root.unitSize - width) / 2;
            y : root.unitSize - height
        }

        Image {
            id: waveformImage
            x: 0
            y: 0
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
                
        ListView {
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
                    if (status == FolderListModel.Ready) {
                        board.setKnobMinMax(0, 0, sampleFileList.count - 1);
                        board.setKnobIsInteger(0, true);
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
        }
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Bang!", "", "", "", "", "", "", "Back"];
        }
    }

    function _loadSample(sampleFile) {
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
        if (padNumber == 0) {
            // BANG !
            lv2Host.noteOn(lv2Id, 60, 127);
        }
    }

    // will be called by main
    function padReleased(padNumber) {
        console.log("pad pressed", padNumber);
        if (padNumber == 0) {
            // BANG !
            lv2Host.noteOff(lv2Id, 60);
        }
        else if (padNumber == 16) {
            // knob 1 switch
            if (sampleFileList.visible) {
                // the list is visible, we load a file / enter a directory
                if (_acceptListEntry()) {
                    // done
                    sampleFileList.visible = false;
                }
            }
            else {
                // the list is not visible yet, make it visible
                sampleFileList.visible = true;
            }
        }
        else if (padNumber == 7) {
            // end of editing
            canvas.endEditInstrument();
        }
    }

    function knobMoved(knobNumber, amount) {
        if (knobNumber==0) {
            if (sampleFileList.visible)
                sampleFileList.currentIndex = amount;
        }
    }

}
