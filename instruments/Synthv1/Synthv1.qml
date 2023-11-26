import QtQuick 2.7
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.11

import Utils 1.0

import "../common"

// TODO
// arturia: knob too fast
// load presets

Item {
    id: root
    // Used by the host to look for an LV2 plugin
    property string lv2Url: "http://synthv1.sourceforge.net/lv2"

    // Set by the host when the instance is created
    property string lv2Id: ""

    signal quit()

    property string name: "Synthv1"

    property bool usePresets: false

    // Set by the host
    property int unitSize: 100

    readonly property int legendSize: 0.3 * unitSize

    implicitWidth: unitSize * 8
    implicitHeight: unitSize * 2 + legendSize * 2


    //------------------ custom properties

    property int _currentSynthNumber: 0

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
        console.log("synthv1 init");

        let children = Utils.findChildren(root);
        for (var i = 0; i < children.length; i++) {
            let child = children[i];
            if (child.parameterName) {
                child.value = lv2Host.getParameterValue(lv2Id, child.parameterName);
            }
        }
    }

    /*Item {
        id: debug_grid
        GridLayout {
            columns: 8
            columnSpacing: 0
            rowSpacing: 0
            // first knob block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: unitSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // first legend block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: legendSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // second knob block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: unitSize
                    border.color: "red"
                    border.width: 1
                }
            }
            // second legend block
            Repeater {
                model: 8
                Rectangle {
                    implicitWidth: unitSize
                    implicitHeight: legendSize
                    border.color: "red"
                    border.width: 1
                }
            }
        }
    }*/

    StackLayout {
        id: mainLayout
        x: 0
        y: 0

        MainPanel { synthNumber: 1 }
        OscPanel { synthNumber: 1 }
        FilterPanel { synthNumber: 1 }
        ModPanel { synthNumber: 1 }

        MainPanel { synthNumber: 2 }
        OscPanel { synthNumber: 2 }
        FilterPanel { synthNumber: 2 }
        ModPanel { synthNumber: 2 }

        FXPanel {}
    }

    function _updatePad() {
        padMenu.updateText(0, ":menu:");
    }
    function _updateInfo() {
        infoScreen.text = "SynthV1 > synth " + (_currentSynthNumber + 1)
    }
    onVisibleChanged : {
        if (visible) {
            _updatePad();
            _updateInfo();
        }
    }

    property bool _inSubMenu: false
    
    // will be called by main
    function padPressed(padNumber) {
        if (! _inSubMenu && padNumber == 0) {
            // enter "menu"
            console.log("push");
            padMenu.pushState();
            padMenu.clear();
            padMenu.updateText(0, "");
            padMenu.updateText(1, "MAIN");
            padMenu.updateText(2, "OSC");
            padMenu.updateText(3, "FILTER");
            padMenu.updateText(4, "MOD");
            padMenu.updateText(5, "FX");
            padMenu.updateText(7, "SYNTH 1/2");
            // disable the current item so that it does not grab the pad / knob focus
            mainLayout.children[mainLayout.currentIndex].enabled = false;

            _inSubMenu = true;
            return;
        }
    }

    function _enableChild(index) {
        console.log("_enabledChild", index);
        mainLayout.children[index].enabled = true;        
    }

    // will be called by main
    function padReleased(padNumber) {
        console.log("main on padreleased");
        if (_inSubMenu) {
            let switchTo = mainLayout.currentIndex;
            switch (padNumber) {
            case 1:
                console.log("**** MAIN ****");
                switchTo = 0 + 4 * _currentSynthNumber;
                break;
            case 2:
                console.log("**** OSC ****");
                switchTo = 1 + 4 * _currentSynthNumber;
                break;
            case 3:
                console.log("**** FILTER ****");
                switchTo = 2 + 4 * _currentSynthNumber;
                break;
            case 4:
                console.log("**** MOD ****");
                switchTo = 3 + 4 * _currentSynthNumber;
                break;
            case 5:
                switchTo = 8;
            case 7:
                // synth 1/2 switch
                _currentSynthNumber = 1 - _currentSynthNumber;
                _updateInfo();
                if (switchTo >= 0 && switchTo < 8) {
                    switchTo = switchTo - 4 * (1 - _currentSynthNumber) + 4 * _currentSynthNumber;
                }
                break;
            }
            _inSubMenu = false;
            // switch to another tab, if needed
            console.log("pop");
            padMenu.popState();
            if (switchTo != mainLayout.currentIndex) {
                padMenu.clear();
                _updatePad();
            }
            // restore the "enabled" state of the current item
            // but do it after all events have been processed
            // especially, PadSwitchMapping events
            // that depend on this state
            Qt.callLater(_enableChild, mainLayout.currentIndex);

            mainLayout.currentIndex = switchTo;
            return;
        }
        
        /*if (padNumber == 7) {
            // end of editing
            quit();
        }*/
    }

}
