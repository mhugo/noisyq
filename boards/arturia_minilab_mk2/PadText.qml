import QtQuick 2.7
import QtQuick.Controls 2.5

Text {
    property int padNumber: 0

    FontLoader {
        id: titleFont
        source: "fonts/big_noodle_titling.ttf"
    }
    
    id: root

    font.family: titleFont.name
    font.pointSize: 14
    color: "white"
    x: (padNumber % 8) * unitSize   + (unitSize - width) / 2
    y: ~~(padNumber / 8) * unitSize + (unitSize - height) / 2
}
