import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

ColumnLayout {
    //---------------------------------------------------
    //
    //                 REQUIRED API
    //
    //---------------------------------------------------
    id: plugin

    // Will be set by the main program
    // once it is instantiated to a given track number
    property int track

    // Keys sent by the main program
    signal keyPressed(int code, int key, int modifiers)
    signal keyReleased(int code, int key, int modifiers)

    //------------ END OF REQUIRED API ------------------

    property int selected: 0

    property bool shifted: false

    Text { text: "Selected " + selected }

    onKeyPressed : {
        // specific keys for helm
        if (code == keycode.k_number1) {
            switchTo("oscPanel");
        }
        else if (code == keycode.k_number2) {
            switchTo("ampEnvelope");
        }
        else if (code == keycode.k_number3) {
            switchTo("filterEnvelope");
        }
        else if ((code >= keycode.k_row1_1) && (code <= keycode.k_row1_8)) {
            selected = code - keycode.k_row1_1;
            if (modifiers & Qt.ShiftModifier)
                selected += 8;
        }
        else if ((code >= keycode.k_row2_1) && (code <= keycode.k_row2_8)) {
            selected = code - keycode.k_row2_1 + 16;
            if (modifiers & Qt.ShiftModifier)
                selected += 8;
        }
        else if (code == keycode.k_right) {
            // look for the selected item
            if (selected < layout.data.length - 1) {
                layout.data[selected].selected = false;
                selected += 1;
                layout.data[selected].selected = true;
            }
        }
        else if (code == keycode.k_left) {
            // look for the selected item
            if (selected > 0) {
                layout.data[selected].selected = false;
                selected -= 1;
                layout.data[selected].selected = true;
            }
        }
        else if (code == keycode.k_capslock) {
            shifted = true;
        }
        else {
            console.log("pass to ", layout.data[selected]);
            layout.data[selected].keyPressed(code, key, modifiers);
        }
    }

    onKeyReleased: {
        if (code == keycode.k_capslock) {
            shifted = false;
        }        
    }

    // switch to a given item by its id
    function switchTo(itemName) {
        // TODO use a constant array ?
        if (itemName === "ampEnvelope") {
            stack.currentIndex = 1;
        }
        else if (itemName === "filterEnvelope") {
            stack.currentIndex = 2;
        }
        else if (itemName === "oscPanel") {
            stack.currentIndex = 0;
        }
    }

    property int bank: 0
    property int program: 0

    Text { text: "Bank " + bank + " Program " + program }

    property var waveEnum : ["sin",
                             "triangle",
                             "square",
                             "saw up",
                             "saw down",
                             "3 step",
                             "4 step",
                             "8 step",
                             "3 pyramid",
                             "5 pyramid",
                             "9 pyramid"]

    ColumnLayout {

        Rectangle {
            width: 100
            height: 40
            border.width: 2
            radius: 10
            color: shifted ? "blue" : "white"
            Text {
                text: "Shift"
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: shifted ? "white" : "black"
            }
        }

        GridLayout {
            id: layout
            columns: 8
            ControlFrame {
                selected: true
                text: "Volume"
                Knob {
                    bindingParameter: "osc_1_volume"
                    displayedFrom: 0.0
                    displayedTo: 16.0
                }
            }
            ControlFrame {
                text: "Wave"
                Knob {
                    enums: waveEnum
                    type: enumKnob
                    bindingParameter: "osc_1_waveform"
                }
            }
            ControlFrame {
                text: "Detune"
                Knob {
                    type: intKnob
                    displayedFrom: -48
                    displayedTo: 48
                    bindingParameter: "osc_1_tune"
                }
            }
            ControlFrame {
                text: "Transpose"
                Knob {
                    type: intKnob
                    displayedFrom: -100
                    displayedTo: 100
                    bindingParameter: "osc_1_transpose"
                }
            }
            ControlFrame {
                text: "Voices"
                Knob {
                    type: intKnob
                    displayedFrom: 1
                    displayedTo: 15
                    bindingParameter: "osc_1_unison_voices"
                }
            }
            ControlFrame {
                text: "V. detune"
                Knob {
                    type: intKnob
                    displayedFrom: 0
                    displayedTo: 100
                    bindingParameter: "osc_1_unison_detune"
                }
            }
            ControlFrame {
                text: "Sub vol."
                Knob {
                    displayedFrom: 0
                    displayedTo: 16
                    bindingParameter: "sub_volume"
                }
            }
            ControlFrame {
                text: "Noise vol."
                Knob {
                    displayedFrom: 0
                    displayedTo: 16
                    bindingParameter: "noise_volume"
                }
            }

            // row 2
            ControlFrame {
                text: "Vol"
                shiftText: "X. mod."
                shifted: plugin.shifted
                Knob {
                    bindingParameter: "osc_2_volume"
                    displayedFrom: 0.0
                    displayedTo: 16.0
                    visible: ! shifted
                }
                Knob {
                    bindingParameter: "cross_modulation"
                    displayedFrom: 0.0
                    displayedTo: 100.0
                    visible: shifted
                }
            }
            ControlFrame {
                text: "Wave"
                Knob {
                    enums: waveEnum
                    type: enumKnob
                    bindingParameter: "osc_2_waveform"
                }
            }
            ControlFrame {
                text: "Detune"
                Knob {
                    type: intKnob
                    displayedFrom: -48
                    displayedTo: 48
                    bindingParameter: "osc_2_tune"
                }
            }
            ControlFrame {
                text: "Transpose"
                Knob {
                    type: intKnob
                    displayedFrom: -100
                    displayedTo: 100
                    bindingParameter: "osc_2_transpose"
                }
            }
            ControlFrame {
                text: "Voices"
                Knob {
                    type: intKnob
                    displayedFrom: 1
                    displayedTo: 15
                    bindingParameter: "osc_2_unison_voices"
                }
            }
            ControlFrame {
                text: "V. detune"
                Knob {
                    type: intKnob
                    displayedFrom: 0
                    displayedTo: 100
                    bindingParameter: "osc_2_unison_detune"
                }
            }
            ControlFrame {
                text: "Sub wave"
                Knob {
                    type: enumKnob
                    enums: waveEnum
                    bindingParameter: "sub_waveform"
                }
            }
            ControlFrame {
                text: "Sub shuffle"
                Knob {
                    type: intKnob
                    displayedFrom: 0
                    displayedTo: 100
                    bindingParameter: "sub_shuffle"
                }
            }

            // buttons
            ControlFrame {
                Pad {
                    color: "#ff1412"
                }
            }
            ControlFrame {
                Pad {
                }
            }
        }
    }
}
