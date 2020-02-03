import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

StackLayout {
    anchors.fill:parent
    currentIndex: 0

    property string lv2InstanceName

    // switch to a given item by its id
    function switchTo(itemName) {
        // TODO use a constant array ?
        if (itemName === "ampEnvelope") {
            currentIndex = 0;
        }
        else if (itemName === "filterEnvelope") {
            currentIndex = 1;
        }
        else if (itemName === "oscPanel") {
            currentIndex = 2;
        }
    }

    Envelope {
        id: ampEnvelope
        title: "Amplitude Envelope"

        Component.onCompleted : {
            lv2Binding.set(this, "attackChanged", "attack", lv2InstanceName, "amp_attack", 0.0, 16.0, 0.0, 1.0);
            lv2Binding.set(this, "decayChanged", "decay", lv2InstanceName, "amp_decay", 0.0, 16.0, 0.0, 1.0);
            lv2Binding.set(this, "sustainChanged", "sustain", lv2InstanceName, "amp_sustain", 0.0, 1.0, 0.0, 1.0);
            lv2Binding.set(this, "releaseChanged", "release", lv2InstanceName, "amp_release", 0.0, 16.0, 0.0, 1.0);
        }
    }

    ColumnLayout {
        id: filterEnvelope
        Switch {
            id: filterEnabled
            checked: false
            text: "Enable filter"
            Component.onCompleted : {
                lv2Binding.set(this, "checkedChanged", "checked", lv2InstanceName, "filter_on", 0.0, 1.0, 0.0, 1.0);
            }
        }
        Envelope {
            enabled: filterEnabled.checked
            title: "Filter Envelope"
            Component.onCompleted : {
                lv2Binding.set(this, "attackChanged", "attack", lv2InstanceName, "fil_attack", 0.0, 16.0, 0.0, 1.0);
                lv2Binding.set(this, "decayChanged", "decay", lv2InstanceName, "fil_decay", 0.0, 16.0, 0.0, 1.0);
                lv2Binding.set(this, "sustainChanged", "sustain", lv2InstanceName, "fil_sustain", 0.0, 1.0, 0.0, 1.0);
                lv2Binding.set(this, "releaseChanged", "release", lv2InstanceName, "fil_release", 0.0, 16.0, 0.0, 1.0);
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
                Component.onCompleted : {
                    lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "sub_volume", from, to, 0.0, 1.0);
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
                    lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "sub_waveform", 0.0, 1.0, 0.0, 1.0);
                }
            }
            Switch {
                text: "Sub octave"
                Component.onCompleted : {
                    lv2Binding.set(this, "checkedChanged", "checked", lv2InstanceName, "sub_octave", 0.0, 1.0, 0.0, 1.0);
                }
            }
            Knob {
                text: "Sub shuffle"
                units: "cents"
                from: 0.0
                to: 100.0
                Component.onCompleted : {
                    lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "sub_shuffle", from, to, 0.0, 1.0);
                }
            }
        }

        RowLayout {
            Text { text: "Noise" }
            Knob {
                text: "Volume"
                Component.onCompleted : {
                    lv2Binding.set(this, "valueChanged", "value", lv2InstanceName, "noise_volume", from, to, 0.0, 1.0);
                }
            }            
        }
    }
}
