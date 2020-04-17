import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0

import Binding 1.0

ColumnLayout {
    id: root

    property color color : "#d90243"
    Rectangle
    {
        width: 64
        height: 64
        radius: 6
        color: root.color
        Image {
            y: parent.y + 6
            x: parent.x + 6
            source: "pad.svg"
            sourceSize.width: 52
            sourceSize.height: 52
        }
    }
}
