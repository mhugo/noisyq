import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Utils 1.0

import Qt.labs.folderlistmodel 2.11

ColumnLayout {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://samplv1.sourceforge.net/lv2"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Samplv1"

    property int unitSize: 100

    //------------------ custom properties

    property string sampleFileName

    // Automatically save values of objects with "saveState" property defined
    // Use its id as parameter name
    function saveState() {
    }

    function loadState(state) {
    }

    // Initialize a state, reading from the living LV2 process
    function init() {
        console.log("samplv1 init");
    }

    ColumnLayout {
        ListView {
            id: sampleFileList
            width: main.unitSize * 2
            height: main.unitSize
            model: FolderListModel {
                rootFolder: "/home/hme/perso/music/samples"
                folder: "/home/hme/perso/music/samples"
                nameFilters: ["*.wav", "*.aif", "*.flac"]

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

        Text {
            text: "Sample " + sampleFileName
        }
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Load", "", "", "", "", "", "", "Back"];
        }
    }

    // will be called by main
    function padReleased(padNumber) {
        if (padNumber == 0) {
            // enter a directory
            if (sampleFileList.model.isFolder(sampleFileList.currentIndex)) {
                sampleFileList.model.folder += "/" + sampleFileList.model.get(sampleFileList.currentIndex, "fileName");
                sampleFileList.currentIndex = 0;
                return;
            }
            let sampleFile = sampleFileList.model.folder + "/" + sampleFileList.model.get(sampleFileList.currentIndex, "fileName");
            // remove "file://"
            sampleFile = sampleFile.slice(7);

            // manipulate the state in order to include the sample file
            const sample_file_key = "http://samplv1.sourceforge.net/lv2#P101_SAMPLE_FILE";
            let state_str = lv2Host.save_state(lv2Id, /* convert_xml_to_json */ true);
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
        else if (padNumber == 7) {
            // end of editing
            canvas.endEditInstrument();
        }
    }

    function knobMoved(knobNumber, amount) {
        if (knobNumber==0) {
            sampleFileList.currentIndex = amount;
        }
    }

}
