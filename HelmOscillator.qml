import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

RowLayout {
    // oscillator number
    property int oscillatorNumber

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

    ControlFrame {
        text: "Volume"
        selected: true
        Knob {
            BindingDeclaration {
                parameterName: "osc_" + oscillatorNumber + "_volume"
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
                parameterName: "osc_" + oscillatorNumber + "_waveform"
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
                parameterName: "osc_" + oscillatorNumber + "_detune"
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
                parameterName: "osc_" + oscillatorNumber + "_transpose"
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
                parameterName: "osc_" + oscillatorNumber + "_unison_voices"
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
                parameterName: "osc_" + oscillatorNumber + "_unison_detune"
                propertyMin: parent.from
                propertyMax: parent.to
            }
        }
    }
    ColumnLayout {
        Text { text: "Harmonize unison" }
        Switch {
            BindingDeclaration {
                parameterName: "osc_" + oscillatorNumber + "_harmonize"
                propertyName: "checked"
            }
        }
    }
}
