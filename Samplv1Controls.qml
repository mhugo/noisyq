import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import Binding 1.0

ColumnLayout {
    property int bank: 0
    property int program: 0

    Text { text: "Bank " + bank + " Program " + program }

}
