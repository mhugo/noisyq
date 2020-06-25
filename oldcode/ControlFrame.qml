import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    id: root
    default property alias data: childItem.data
    property string text
    /* Additional text to display if a "shifted" control is defined */
    property string shiftText : ""
    /* Whether the control is selected or not */
    property bool selected: false
    /* While true, toggle the visibility to the second visual child */
    property bool shifted: false

    property real margin: 8

    signal keyPressed(int code, int key, int modifiers)
    signal keyReleased(int code, int key, int modifiers)
    onKeyPressed: {
        console.log("cf keypressed");
        childItem.data[shifted && data.length > 1 ? 1 : 0].keyPressed(code, key, modifiers);
    }
    onKeyReleased: {
        childItem.data[shifted && data.length > 1 ? 1 : 0].keyReleased(code, key, modifiers);
    }
    
    Text {
        text: {
            if (!shifted) {
                "<b>" + root.text + "</b>" + (shiftText ? "|" + shiftText : "");
            }
            else {
                root.text + (shiftText ? "|<b>" + shiftText + "</b>" : "");
            }
        }
    }
    Rectangle {
        width: childrenRect.width + margin
        height: childrenRect.height + margin
        radius: 5
        border.color: "blue"
        border.width: selected ? 2 : 0
    
        ColumnLayout {
            id: childItem
            transform: Translate { x: margin/2.; y:margin/2. }
        }
    }
}
