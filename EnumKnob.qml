import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

//
// A parameter that is controlled by a knob that represents a choice in a fixed list of possibilites
// a.k.a. an enumerated value

ColumnLayout {
    property string text
    // internal value
    property real value

    // minimum internal value
    property real from : 0.0
    // maximum internal value
    property real to : 1.0

    // list of enum strings
    property var enums : ["A", "B"]
    // enum index of the current enum
    property int displayed_enum_index
    // current enum value
    property string displayed_enum

    Dial {
        id: dial
        from: 0
        to: parent.enums.length - 1
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
        snapMode: Dial.SnapAlways
        stepSize: 1
        function updateDisplay() {
            parent.displayed_enum_index = value;
            parent.displayed_enum = parent.enums[parent.displayed_enum_index];
            parent.value = value / to * (parent.to - parent.from) + parent.from;            
        }
        onValueChanged: {
            updateDisplay();
        }
        //Component.onCompleted : {
        //    updateDisplay();
        //}
        Text {
            text: parent.parent.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
        }
    }
    Text {
        text: parent.displayed_enum
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
