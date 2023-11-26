import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

import "../common"

Item {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "/home/hme/perso/music/vst/linux/dexed/Dexed.so"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property bool usePresets: false

    signal quit()

    property string name: "Dexed"

    // Set by the host
    property int unitSize: 100

    readonly property int legendSize: 0.3 * unitSize

    implicitWidth: unitSize * 8
    implicitHeight: unitSize * 2 + legendSize * 2


    //------------------ custom properties

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
            "parameters" : d
        };
    }

    function loadState(state) {
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
        console.log("Dexed init");

        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.parameterName) {
                child.value = lv2Host.getParameterValue(lv2Id, child.parameterName);
            }
        }
    }

}
