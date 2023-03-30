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

    Text {
        x: unitSize * 1
        y: unitSize + legendSize
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
                text: root.name
                font.pixelSize: unitSize / 3
                font.family: monoFont.name
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
            }
        }
    }
    // Initialize a state, reading from the living LV2 process
    function init() {
    }
}
