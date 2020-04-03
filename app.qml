/*
TODO
- map more controls
- route midi keyboard notes events to midi in of each instance
- find how to configure midi in control changes binding
- add a virtual piano
- dynamic loading of plugin: ensure errors are reported
*/
import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Midi 1.0

import Tracks 1.0

Item {
    id: main
    width: childrenRect.width
    height: childrenRect.height

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
            text: "Current track " + (tracks.currentTrack + 1)
        }

        RowLayout {
            Text { text: "Load preset" }
            ComboBox {
                id: presetCombo
            }
        }

        Tracks {
            width: childrenRect.width
            height: childrenRect.height
            id: tracks

            onCurrentTrackChanged : {
                console.log("current track changed from qml", currentTrack);
            }
        }

        Sequencer {
            id: seq
            objectName: "sequencer"
            
            currentVoice : tracks.currentTrack
        }
    }
    
    Connections {
        target: main

        onKeyPressed: {
            if (code == keycode.k_escape) {
                Qt.quit();
            }
            else if ((code >= keycode.k_f1) && (code <= keycode.k_f8)) {
                console.log("currentItem", tracks.currentItem);
                if ((tracks.currentItem === null) &&
                    (modifiers & Qt.ControlModifier )) {
                    // load a plugin
                    let pluginNumber = code - keycode.k_f1;
                    if (pluginNumber == 0) {
                        tracks.instantiate_plugin("HelmControls.qml", "http://tytel.org/helm", tracks.currentTrack);
                    }
                    else if (pluginNumber == 1) {
                        tracks.instantiate_plugin("Samplv1Controls.qml", "http://samplv1.sourceforge.net/lv2", tracks.currentTrack);
                    }
                }
                else if (! (modifiers & Qt.ControlModifier) ) {
                    let voiceNumber = code - keycode.k_f1;
                    console.log("switch to track #" + voiceNumber);
                    if (voiceNumber < tracks.count) {
                        console.log("switch to track #" + voiceNumber);
                        tracks.currentTrack = voiceNumber;
                    }
                }
            }
            else if ((code >= keycode.k_row3_1) && (code <= keycode.k_row3_10)) {
                // 69 : A4
                let note = code - keycode.k_row3_1 + 69;
                noteOn(tracks.currentTrack, note);
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
            else {
                if (tracks.currentItem) {
                    tracks.currentItem.keyPressed(code, key, modifiers);
                }
            }
        }
        onKeyReleased: {
            console.log("on released", code);
            if ((code >= keycode.k_row3_1) && (code <= keycode.k_row3_10)) {
                // 69 : A4
                let note = code - keycode.k_row3_1 + 69;
                noteOff(tracks.currentStack, note);
            }
        }
    }
}
