import QtQuick 2.7

Item {
    id: root
    property int padNumber: 0
    property alias text: sub_text.text

    signal padPressed();
    signal padReleased();

    x: (padNumber % 8) * unitSize
    y: unitSize * (~~(padNumber / 8)) + (unitSize + legendSize) * 2

    Text {
        id: sub_text
        x: (unitSize - width) / 2
        y: (unitSize - height) / 2
        font.family: titleFont.name
        font.pointSize: 14
        color: "white"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Connections {
        target: board
        onPadPressed: {
            if (padNumber == root.padNumber) {
                padPressed();
            }
        }
        onPadReleased: {
            if (padNumber == root.padNumber) {
                padReleased();
            }
        }
        enabled: root.visible & root.enabled
    }
}
