import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

//
// A parameter that is controlled by a knob that represents an integer value

ColumnLayout {
    property string units
    // internal value
    property real value

    // minimum internal value
    property real from : 0.0
    // maximum internal value
    property real to : 1.0

    // minimum displayed value
    property int displayed_from: 0
    // maximum displayed value
    property int displayed_to: 9
    // current displayed value
    property int displayed_value
    // default value
    property int displayed_default: displayed_from

    Dial {
        id: dial
        from: parent.displayed_from
        to: parent.displayed_to
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
        snapMode: Dial.SnapAlways
        stepSize: 1
        onValueChanged: {
            parent.displayed_value = value;
            parent.value = (value - parent.displayed_from) / (parent.displayed_to - parent.displayed_from) * (parent.to - parent.from) + parent.from;
        }
        Text {
            text: parent.parent.displayed_value
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
        }
        Component.onCompleted: {
            value = parent.displayed_default;
        }
    }
}
