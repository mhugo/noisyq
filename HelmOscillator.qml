import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

RowLayout {
    // oscillator number
    property int oscillatorNumber
    Text { text: "Osc. " + oscillatorNumber }
    Knob {
        text: "Volume"
        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_volume", from, to, 0.0, 1.0);
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

        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_waveform", 0.0, 1.0, 0.0, 1.0);
        }
    }
    IntKnob {
        text: "T"
        units: "semitones"
        displayed_from: -48.0
        displayed_to: 48.0
        displayed_default: 0.0
        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_transpose", 0.0, 1.0, 0.0, 1.0);
        }
    }
    Knob {
        text: "t"
        units: "cents"
        from: -100.0
        to: 100.0
        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_transpose", from, to, 0.0, 1.0);
        }
    }
    IntKnob {
        text: "Voices"
        displayed_from: 1
        displayed_to: 15
        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_unison_voices", from, to, 0.0, 1.0);
        }
    }
    Knob {
        text: "Unison tune"
        units: "cents"
        to: 100.0
        Component.onCompleted : {
            lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "osc_" + oscillatorNumber + "_unison_detune", from, to, 0.0, 1.0);
        }
    }
    Switch {
        text: "Harmonize unison"
        Component.onCompleted : {
            lv2Binding.set(this, "checkedChanged", "checked", lv2InstanceName, "unison_" + oscillatorNumber + "_harmonize", 0.0, 1.0, 0.0, 1.0);
        }
    }
    Component.onCompleted : {
        console.log("***** HelmOscillator " + oscillatorNumber);
    }
}
