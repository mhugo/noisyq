import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Midi 1.0

Item {
    width: 600
    height: 600


    MidiIn {
        id: midi_in
        port: Qt.application.arguments[1] || ""

        onDataReceived : {
            console.log(data);
            if ( (data[0] == 0xB1) && (data[1] == 1) ) {
                adsr.attack = data[2] / 127.0 * 16;
            }
        }
    }

    StackView {
        initialItem: ampEnvelope
        anchors.fill:parent

        Component{
            id: ampEnvelope
            Envelope {
                title: "Amplitude Envelope"
            }
        }

        Component{
            id: filterEnvelope
            Envelope {
                title: "Filter Envelope"
            }
        }
    }
}
