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
        else if (code == keycode.k_right) {
            selected += 1;
        }
        else if (code == keycode.k_left) {
            selected -= 1;
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
    StackLayout {
        id: stack
        //anchors.fill:parent
        currentIndex: 0

        GridLayout {
            columns: 8
            ControlFrame {
                text: "Volume"
                selected: true
                Knob {
                    BindingDeclaration {
                        parameterName: "osc_1_volume"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Wave"
                EnumKnob {
                    enums: waveEnum
                    BindingDeclaration {
                        parameterName: "osc_1_waveform"
                    }
                }
            }
            ControlFrame {
                text: "Transpose"
                IntKnob {
                    units: "semitones"
                    displayed_from: -48.0
                    displayed_to: 48.0
                    displayed_default: 0.0
                    BindingDeclaration {
                        parameterName: "osc_1_detune"
                    }
                }
            }
            ControlFrame {
                text: "Tune"
                Knob {
                    units: "cents"
                    from: -100.0
                    to: 100.0
                    BindingDeclaration {
                        parameterName: "osc_1_transpose"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Voices"
                IntKnob {
                    displayed_from: 1
                    displayed_to: 15
                    BindingDeclaration {
                        parameterName: "osc_1_unison_voices"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Unison tune"
                Knob {
                    units: "cents"
                    to: 100.0
                    BindingDeclaration {
                        parameterName: "osc_1_unison_detune"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ColumnLayout {
                Text { text: "Harmonize unison" }
                Switch {
                    BindingDeclaration {
                        parameterName: "osc_1_harmonize"
                        propertyName: "checked"
                    }
                }
            }
            ControlFrame {
                Knob {
                    enabled: false
                }
            }

            // second row
            ControlFrame {
                text: "Volume"
                selected: true
                Knob {
                    BindingDeclaration {
                        parameterName: "osc_2_volume"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Wave"
                EnumKnob {
                    enums: waveEnum
                    BindingDeclaration {
                        parameterName: "osc_2_waveform"
                    }
                }
            }
            ControlFrame {
                text: "Transpose"
                IntKnob {
                    units: "semitones"
                    displayed_from: -48.0
                    displayed_to: 48.0
                    displayed_default: 0.0
                    BindingDeclaration {
                        parameterName: "osc_2_detune"
                    }
                }
            }
            ControlFrame {
                text: "Tune"
                Knob {
                    units: "cents"
                    from: -100.0
                    to: 100.0
                    BindingDeclaration {
                        parameterName: "osc_2_transpose"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Voices"
                IntKnob {
                    displayed_from: 1
                    displayed_to: 15
                    BindingDeclaration {
                        parameterName: "osc_2_unison_voices"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame {
                text: "Unison tune"
                Knob {
                    units: "cents"
                    to: 100.0
                    BindingDeclaration {
                        parameterName: "osc_2_unison_detune"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ColumnLayout {
                Text { text: "Harmonize unison" }
                Switch {
                    BindingDeclaration {
                        parameterName: "osc_2_harmonize"
                        propertyName: "checked"
                    }
                }
            }

            // third row
            ControlFrame {
                text: "Sub Vol"
                Knob {
                    BindingDeclaration {
                        parameterName: "sub_volume"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
            ControlFrame{
                text: "Wave"
                EnumKnob {
                    enums: waveEnum
                    BindingDeclaration { parameterName: "sub_waveform" }
                }
            }
            Switch {
                text: "Sub octave"
                BindingDeclaration {
                    propertyName: "checked"
                    parameterName: "sub_shuffle"
                }
            }
            ControlFrame {
                text: "Sub shuffle"
                Knob {
                    units: "cents"
                    from: 0.0
                    to: 100.0
                    BindingDeclaration {
                        parameterName: "sub_shuffle"
                        propertyMin: parent.from
                        propertyMax: parent.to
                    }
                }
            }
        }
            
        ControlFrame {
            text: "Noise Vol"
            Knob {
                BindingDeclaration { parameterName: "noise_volume" }
            }
        }

        Envelope {
            id: ampEnvelope
            title: "Amplitude Envelope"

            BindingDeclaration {
                propertyName: "attack"
                parameterName: "amp_attack"
                propertyMax: 16.0
            }
            BindingDeclaration {
                propertyName: "decay"
                parameterName: "amp_decay"
                propertyMax: 16.0
            }
            BindingDeclaration {
                propertyName: "sustain"
                parameterName: "amp_sustain"
                propertyMax: 1.0
            }
            BindingDeclaration {
                propertyName: "release"
                parameterName: "amp_release"
                propertyMax: 16.0
            }
        }

        ColumnLayout {
            id: filterEnvelope
            Switch {
                id: filterEnabled
                checked: false
                text: "Enable filter"
                BindingDeclaration {
                    propertyName: "checked"
                    parameterName: "filter_on"
                }
            }
            Envelope {
                enabled: filterEnabled.checked
                title: "Filter Envelope"
                BindingDeclaration {
                    propertyName: "attack"
                    parameterName: "fil_attack"
                    propertyMax: 16.0
                }
                BindingDeclaration {
                    propertyName: "decay"
                    parameterName: "fil_decay"
                    propertyMax: 16.0
                }
                BindingDeclaration {
                    propertyName: "sustain"
                    parameterName: "fil_sustain"
                    propertyMax: 1.0
                }
                BindingDeclaration {
                    propertyName: "release"
                    parameterName: "fil_release"
                    propertyMax: 16.0
                }
            }

        }

    }
}
