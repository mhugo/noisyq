import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

RowLayout {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://tytel.org/helm"

    // Set by the host when the instance is created
    property string lv2Id: ""

    property string name: "Helm"

    // shortcut
    function _setLV2(param, value) {
        lv2Host.setParameterValue(lv2Id, param, value);
    }

    function saveState() {
        return {
            "knobs" : [dial1.value, dial2.value]
        };
    }

    function loadState(state) {
        dial1.value = state["knobs"][0];
        dial2.value = state["knobs"][1];
    }

    Slider {
        id: slider1
        orientation: Qt.Vertical
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2("slide", value);
        }
    }
    Dial {
        id: dial1
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64

        onValueChanged: {
            _setLV2("ok", value);
        }
    }
    Dial {
        id: dial2
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
    }

    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
            infoScreen.text = "Helm";

            board.setKnobValue(0, dial1.value);
            board.setKnobValue(1, dial2.value);
        }
    }

    Connections {
        target: board

        // only visible panels should react to knob / pad changes
        enabled: root.visible

        onKnobMoved : {
            switch (knobNumber) {
            case 0:
                dial1.value = amount;
                break;
            case 1:
                dial2.value = amount;
                break;
            }
        }
    }
}


