import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

ColumnLayout {
    // must be present, set by the main program
    // once it is instantiated to a given track number
    property int track

    // switch to a given item by its id
    function switchTo(itemName) {
        // TODO use a constant array ?
        if (itemName === "ampEnvelope") {
            stack.currentIndex = 0;
        }
        else if (itemName === "filterEnvelope") {
            stack.currentIndex = 1;
        }
        else if (itemName === "oscPanel") {
            stack.currentIndex = 2;
        }
    }

    property int voice : 0
    property int bank: 0
    property int program: 0

    Text { text: "Bank " + bank + " Program " + program }

    StackLayout {
        id: stack
    //anchors.fill:parent
    currentIndex: 0


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

    ColumnLayout {
        HelmOscillator {
            oscillatorNumber: 1
        }
        HelmOscillator {
            oscillatorNumber: 2
        }
        RowLayout {
            // sub oscillator
            Text { text: "Sub" }
            Knob {
                text: "Volume"
                BindingDeclaration {
                    parameterName: "sub_volume"
                    propertyMin: parent.from
                    propertyMax: parent.to
                }
            }
            EnumKnob {
                text: "W"
                enums: ["sin",
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

                BindingDeclaration { parameterName: "sub_waveform" }
            }
            Switch {
                text: "Sub octave"
                BindingDeclaration {
                    propertyName: "checked"
                    parameterName: "sub_shuffle"
                }
            }
            Knob {
                text: "Sub shuffle"
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
        
        RowLayout {
            Text { text: "Noise" }
            Knob {
                text: "Volume"
                BindingDeclaration { parameterName: "noise_volume" }
            }
        }
    }
}
}
