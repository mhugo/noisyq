import QtQuick 2.7

//
// An ADSR envelope control positioned on the canvas
//
// This spans 4 horizontal cells on the canvas.
//
// Variables that need to exist in the scope:
// - unitSize : size * the main widget
// - legendSize : size of the legend below the widget

Item {
    x: (startKnobNumber  % 8) * unitSize
    y: (unitSize + legendSize) * (~~(startKnobNumber / 8))

    // Will take 4 knobs in a row starting from here
    property int startKnobNumber

    property alias attackParameter: envAttack.parameterName
    property alias decayParameter: envDecay.parameterName
    property alias sustainParameter: envSustain.parameterName
    property alias releaseParameter: envRelease.parameterName
    
    KnobMapping {
        id: envAttack
        knobNumber: startKnobNumber

        Text {
            text: "Attack"
            x: (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
        }
    }
    KnobMapping {
        id: envDecay
        knobNumber: startKnobNumber + 1

        Text {
            text: "Decay"
            x: unitSize + (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
        }
    }
    KnobMapping {
        id: envSustain
        knobNumber: startKnobNumber + 2

        Text {
            text: "Sustain"
            x: unitSize * 2 + (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
        }
    }
    KnobMapping {
        id: envRelease
        knobNumber: startKnobNumber + 3

        Text {
            text: "Release"
            x: unitSize * 3 + (unitSize - width) / 2
            y: unitSize + (legendSize - height) / 2
        }
    }

    Canvas {
        id: envCanvas
        width: 4 * unitSize
        height: unitSize
        onPaint: {
            var ctx = getContext("2d");
            var gradient = ctx.createLinearGradient(100, 100, 0, 0);
            gradient.addColorStop(0, '#1f93c2');
            gradient.addColorStop(1, '#a5d4e7');
            ctx.reset();

            ctx.fillStyle = '#11536d';
            ctx.fillRect(0, 0, 4*unitSize, unitSize);

            ctx.fillStyle = gradient;
            ctx.moveTo(0, unitSize);
            ctx.lineTo(unitSize * envAttack.value, 0);
            ctx.lineTo(unitSize * envAttack.value + unitSize * envDecay.value, envSustain.value * unitSize);
            ctx.lineTo(unitSize * envAttack.value + unitSize * envDecay.value + unitSize, envSustain.value * unitSize);
            ctx.lineTo(unitSize * envAttack.value + unitSize * envDecay.value + unitSize + envRelease.value * unitSize, unitSize);
            ctx.lineTo(0, unitSize);
            ctx.fill();
            ctx.lineWidth = 3.0;
            ctx.strokeStyle = '#e9f4f9';
            ctx.stroke();
        }

        Connections {
            target: envAttack
            onValueChanged: {
                envCanvas.requestPaint();
            }
        }
        Connections {
            target: envDecay
            onValueChanged: {
                envCanvas.requestPaint();
            }
        }
        Connections {
            target: envSustain
            onValueChanged: {
                envCanvas.requestPaint();
            }
        }
        Connections {
            target: envRelease
            onValueChanged: {
                envCanvas.requestPaint();
            }
        }
    }
}
