import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

RowLayout {
    property string lv2Url: "http://tytel.org/helm"

    property string name: "Helm"

    function saveState() {
        return {
            "knobs" : [dial1.value, dial2.value]
        };
    }

    function loadState(state) {
        dial1.value = state["knobs"][0];
        dial2.value = state["knobs"][1];
    }

    Dial {
        id: dial1
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
    }
    Dial {
        id: dial2
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
    }
    onVisibleChanged : {
        if (visible) {
            padMenu.texts = ["Osc", "", "", "", "", "", "", "Back"];
        }
    }
}


