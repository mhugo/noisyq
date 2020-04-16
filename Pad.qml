import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0

import Binding 1.0

ColumnLayout {
    id: root

    property color color : "#444444"
    Rectangle
    {
        width: 64
        height: 64
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.color, 1.5) }
            GradientStop { position: 1.0; color: root.color }
        }
    }
}
