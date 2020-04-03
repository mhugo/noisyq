import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    property string units
    property real value
    onValueChanged: {
        dial.value = value;
    }
    property real from : 0
    property real to : 16
    Dial {
        id: dial
        from: parent.from
        to: parent.to
        Layout.maximumWidth: 64
        Layout.maximumHeight: 64
        onValueChanged: {
            parent.value = value;
        }
        Text {
            text: dial.value.toFixed(2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
        }
    }
}
