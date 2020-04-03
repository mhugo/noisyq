import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    default property alias data: colLayout.data
    property string text
    property real margin: 10
    property bool selected: false
    
    Text {
        text: parent.text
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
    }
    Rectangle {
        width: childrenRect.width + margin
        height: childrenRect.height + margin
        radius: 5
        border.color: "blue"
        border.width: selected ? 2 : 0
        ColumnLayout {
            id: colLayout
            transform: Translate { x: margin/2.; y:margin/2. }
        }
    }
}
