import QtQuick 2.7
import QtQuick.Controls 2.5

Rectangle {
    ////////////////////
    //
    // "Square" knob
    //
    // A kind of progress bar organized in a rounded square.
    //
    // o o o o
    // o     o
    // o     o
    // o o o o

    id: root
    //readonly property int unitSize: 400
    property int value: 0
    property int from: 0 // FIXME ignored
    property int to: 8

    ///////////////////
    //
    // Private part
    //
    ///////////////////

    property int _steps: to + 1

    //readonly property double _lineWidth: unitSize/80
    readonly property double _lineWidth: 2
    readonly property double _outerCircleSize: unitSize / 8
    readonly property double _innerCircleSize: _outerCircleSize / 3
    readonly property int _maxSteps: 16 // divisible by 4
    readonly property int _quadrant: ~~(_maxSteps/4)

    border.color: "black"
    border.width: _lineWidth
    width: unitSize
    height: unitSize
    radius: unitSize / 8

    Repeater {
        model: _steps
        Rectangle {
            x: {
                if (_steps <= _quadrant) {
                    // center horizontally
                    var l = unitSize - _outerCircleSize * 2;
                    var xx = index * l / _quadrant;
                    return xx + (l - (_steps-1) * l / _quadrant) / 2 + _outerCircleSize / 2;
                }
                else {
                    if (index < _quadrant) {
                        return index * (unitSize - _outerCircleSize * 2) / _quadrant + _outerCircleSize / 2;
                    }
                    if (index < 2*_quadrant) {
                        return unitSize - 3 * _outerCircleSize / 2;
                    }
                    if (index < 3*_quadrant) {
                        return unitSize - ((index - 2*_quadrant) * (unitSize - _outerCircleSize * 2) / _quadrant) - 3 * _outerCircleSize / 2;
                    }
                    return _outerCircleSize / 2;
                }
            }
            y: {
                if (_steps <= _quadrant) {
                    // center horizontally
                    return _outerCircleSize / 2;
                }
                else {
                    if (index < _quadrant) {
                        return _outerCircleSize / 2;
                    }
                    if (index < 2*_quadrant) {
                        return (index - _quadrant) * (unitSize - _outerCircleSize * 2) / _quadrant + _outerCircleSize / 2;
                    }
                    if (index < 3*_quadrant) {
                        return unitSize - 3 * _outerCircleSize / 2;
                    }
                    return unitSize - ((index - 3*_quadrant) * (unitSize - _outerCircleSize * 2) / _quadrant) - 3 * _outerCircleSize / 2
                }
            }
            width: _outerCircleSize
            height: _outerCircleSize
            radius: width / 2
            border.width: _lineWidth
            border.color: "black"

            Rectangle {
                x: (_outerCircleSize - _innerCircleSize)/2
                y: (_outerCircleSize - _innerCircleSize)/2
                width: _innerCircleSize
                height: _innerCircleSize
                color: "black"
                radius: width/2
                visible: index <= value
            }
        }
    }
}
