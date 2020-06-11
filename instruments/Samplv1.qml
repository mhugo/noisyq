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
            width: 100
            height: 100
            model: FolderListModel {
                rootFolder: "/home/hme/perso/music/samples"
                folder: "/home/hme/perso/music/samples"
                nameFilters: ["*.wav", "*.aif", "*.flac"]
            }
            delegate : Text {
                text: fileName
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

            board.setKnobMinMax(0, 0, sampleFileList.count);
            board.setKnobIsInteger(0, true);
        }
    }

    // will be called by main
    function padReleased(padNumber) {
        if (padNumber == 0) {
            let sampleFile = sampleFileList.model.folder + "/" + sampleFileList.model.get(sampleFileList.currentIndex, "fileName");
            // remove "file://"
            sampleFile = sampleFile.slice(7);
            console.log("smplaFile", sampleFile);
            console.log(sampleFileList.currentItem);


            console.log("save_state");
            // FIXME: need to manipulate the JSON state !
            let state_str = lv2Host.save_state(lv2Id, /* convert_xml_to_json */ true);
            let state = JSON.parse(state_str);
            let children = state.children[1].children;
            for (var i=0; i < children.length; i++) {
                let child = children[i];
                if (child.tag == "CustomData") {
                    let key = child.children[1].text;
                    if (key == "http://samplv1.sourceforge.net/lv2#P101_SAMPLE_FILE") {
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
                        "text": "http://samplv1.sourceforge.net/lv2#P101_SAMPLE_FILE"
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
