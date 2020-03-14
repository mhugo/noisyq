/*
TODO
- homogénéiser voix (entiers ?), instances et notes midi
  - instance: parametre lv2 + note midi
  - voix: un entier
- map more controls
- route midi keyboard notes events to midi in of each instance
- find how to configure midi in control changes binding
- add a basic sequencer
- allow us to have 8 voices with either a sampler (samplv1) or a synth (helm)
*/
import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Midi 1.0

Item {
    id: main
    width: childrenRect.width
    height: childrenRect.height

    // French keyboard scan codes
    Item {
        id: keycode
        property int k_escape : 9
        property int k_backspace : 22
        property int k_page_up : 112
        property int k_page_down : 117

        property int k_f1 : 67
        property int k_f2 : 68
        property int k_f3 : 69
        property int k_f4 : 70
        property int k_f5 : 71
        property int k_f6 : 72
        property int k_f7 : 73
        property int k_f8 : 74
        property int k_f9 : 75
        property int k_f10 : 76
        property int k_f11 : 77
        property int k_f12 : 78

        property int k_number1 : 10
        property int k_number2 : 11
        property int k_number3 : 12
        property int k_number4 : 13
        property int k_number5 : 14
        property int k_number6 : 15
        property int k_number7 : 16
        property int k_number8 : 17
        property int k_number9 : 18
        property int k_number10 : 19
        property int k_number11 : 20
        property int k_number12 : 21

        // azerty...
        property int k_row1_1 : 24
        property int k_row1_2 : 25
        property int k_row1_3 : 26
        property int k_row1_4 : 27
        property int k_row1_5 : 28
        property int k_row1_6 : 29
        property int k_row1_7 : 30
        property int k_row1_8 : 31
        property int k_row1_9 : 32
        property int k_row1_10 : 33
        property int k_row1_11 : 34
        property int k_row1_12 : 35

        // qsdf...
        property int k_row2_1 : 38
        property int k_row2_2 : 39
        property int k_row2_3 : 40
        property int k_row2_4 : 41
        property int k_row2_5 : 42
        property int k_row2_6 : 43
        property int k_row2_7 : 44
        property int k_row2_8 : 45
        property int k_row2_9 : 46
        property int k_row2_10 : 47
        property int k_row2_11 : 48
        property int k_row2_12 : 49

        // wxcv...
        property int k_row3_1 : 52
        property int k_row3_2 : 53
        property int k_row3_3 : 54
        property int k_row3_4 : 55
        property int k_row3_5 : 56
        property int k_row3_6 : 57
        property int k_row3_7 : 58
        property int k_row3_8 : 59
        property int k_row3_9 : 60
        property int k_row3_10 : 61
    }

    signal keyPressed(int code, int key, int modifiers)
    signal keyReleased(int code, int key, int modifiers)
    focus: true

    signal noteOn(int voice, int note)
    signal noteOff(int voice, int note)
    signal programChange(int voice, int bank, int program)
        
    Keys.onPressed: {
        if (! event.isAutoRepeat) {
            console.log("scan code " + event.nativeScanCode);
            keyPressed(event.nativeScanCode, event.key, event.modifiers);
        }
    }
    Keys.onReleased: {
        if (! event.isAutoRepeat) {
            keyReleased(event.nativeScanCode, event.key, event.modifiers);
        }
    }

/*    MidiIn {
        id: midi_in
        port: Qt.application.arguments[1] || ""

        onDataReceived : {
            console.log(data);
            if ( (data[0] == 0xB1) && (data[1] == 1) ) {
                adsr.attack = data[2] / 127.0 * 16;
            }
        }
    }*/

    ColumnLayout {

        Text {
            text: "Current voice " + (voiceStack.currentIndex + 1)
        }

        RowLayout {
            Text { text: "Load preset" }
            ComboBox {
                id: presetCombo
            }
        }

        Component {
            id: helmPlugin
            HelmControls {
                onProgramChanged : {
                    console.log("programChange", voice, program);
                    programChange(voice, bank, program);
                }
                onBankChanged : {
                    console.log("bankChange", voice, bank);
                    programChange(voice, bank, program);
                }
            }
        }

        Component {
            id: samplv1Plugin
            Samplv1Controls {
                onProgramChanged : {
                    console.log("programChange", voice, program);
                    programChange(voice, bank, program);
                }
                onBankChanged : {
                    console.log("bankChange", voice, bank);
                    programChange(voice, bank, program);
                }
            }
        }
        StackLayout {
            id: voiceStack

            Repeater {
                model: tracks.count()
                Loader {
                    id: pluginLoader
                }
            }
        }

        Sequencer {
            id: seq

            currentVoice : voiceStack.currentIndex
        }
    }
    
    Connections {
        target: main

        onKeyPressed: {
            let currentPlugin = voiceStack.itemAt(voiceStack.currentIndex).item;
            if (code == keycode.k_escape) {
                Qt.quit();
            }
            else if ((code >= keycode.k_f1) && (code <= keycode.k_f8)) {
                if ((currentPlugin === null) &&
                    (modifiers & Qt.ControlModifier )) {
                    // load a plugin
                    let pluginNumber = code - keycode.k_f1;
                    if (pluginNumber == 0) {
                        voiceStack.itemAt(voiceStack.currentIndex).sourceComponent = helmPlugin;
                        tracks.instantiate_plugin("http://tytel.org/helm", voiceStack.currentIndex);
                    }
                    else if (pluginNumber == 1) {
                        voiceStack.itemAt(voiceStack.currentIndex).sourceComponent = samplv1Plugin;
                        tracks.instantiate_plugin("http://samplv1.sourceforge.net/lv2", voiceStack.currentIndex);
                    }
                }
                else if (! (modifiers & Qt.ControlModifier) ) {
                    let voiceNumber = code - keycode.k_f1;
                    if (voiceNumber < voiceStack.count) {
                        voiceStack.currentIndex = voiceNumber;
                    }
                }
            }
            else if ((code >= keycode.k_row3_1) && (code <= keycode.k_row3_10)) {
                // 69 : A4
                let note = code - keycode.k_row3_1 + 69;
                noteOn(voiceStack.currentIndex, note);
            }
            else if (code == keycode.k_page_up) {
                if (modifiers & Qt.ShiftModifier) {
                    currentPlugin.bank += 1;
                }
                else {
                    if (currentPlugin.program < 127)
                        currentPlugin.program += 1;
                }
            }
            else if (code == keycode.k_page_down) {
                if (modifiers & Qt.ShiftModifier) {
                    if (currentPlugin.bank > 0)
                        currentPlugin.bank -= 1;
                }
                else {
                    if (currentPlugin.program > 0)
                        currentPlugin.program -= 1;
                }
            }
            else if (voiceStack.currentIndex < 2) {
                // specific keys for helm
                if (code == keycode.k_number1) {
                    currentPlugin.switchTo("ampEnvelope");
                }
                else if (code == keycode.k_number2) {
                    currentPlugin.switchTo("filterEnvelope");
                }
                else if (code == keycode.k_number3) {
                    currentPlugin.switchTo("oscPanel");
                }
            }
            else if (voiceStack.currentIndex == 2) {
                // specific keys for samplv1
            }
        }
        onKeyReleased: {
            console.log("on released", code);
            if ((code >= keycode.k_row3_1) && (code <= keycode.k_row3_10)) {
                // 69 : A4
                let note = code - keycode.k_row3_1 + 69;
                noteOff(voiceStack.currentIndex, note);
            }
        }
    }

}
