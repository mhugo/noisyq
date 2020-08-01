import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    PlacedKnobMapping {
        legend: "Cutoff"
        mapping.parameterName: "DCF1_CUTOFF"
        mapping.knobNumber: 1

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: parent.value.toFixed(2)
        }
    }
}
