import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import "../common"

Item {
    id: root

    PlacedKnobMapping {
        legend: "Effect #"
        mapping.parameterDisplay: "Effect #"
        mapping.knobNumber: 0
        mapping.isInteger: true
        mapping.min: 0
        mapping.max: 6

        Text {
            x: (unitSize - width) / 2
            y: (unitSize - height) / 2
            text: {
                switch (parent.value) {
                case 0:
                    return "1. Chorus";
                case 1:
                    return "2. Flanger";
                case 2:
                    return "3. Phaser";
                case 3:
                    return "4. Delay";
                case 4:
                    return "5. Reverb";
                case 5:
                    return "6. Compressor";
                case 6:
                    return "7. Limiter";
                }
            }
        }

        onValueChanged : {
            fxStack.currentIndex = ~~value;
        }
    }

    StackLayout {
        id: fxStack
        Item {
            // Chorus
            PlacedKnobMapping {
                legend: "Wet"
                mapping.knobNumber: 1
                mapping.parameterName: "CHO1_WET"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                legend: "Delay"
                mapping.knobNumber: 4
                mapping.parameterName: "CHO1_DELAY"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Feedback"
                mapping.knobNumber: 5
                mapping.parameterName: "CHO1_FEEDB"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Rate"
                mapping.knobNumber: 6
                mapping.parameterName: "CHO1_RATE"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Modulation"
                mapping.knobNumber: 7
                mapping.parameterName: "CHO1_MOD"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
        }

        Item {
            // Flanger
            PlacedKnobMapping {
                legend: "Wet"
                mapping.knobNumber: 1
                mapping.parameterName: "FLA1_WET"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                legend: "Delay"
                mapping.knobNumber: 4
                mapping.parameterName: "FLA1_DELAY"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Feedback"
                mapping.knobNumber: 5
                mapping.parameterName: "FLA1_FEEDB"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Rate"
                mapping.knobNumber: 6
                mapping.parameterName: "FLA1_DAFT"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
        }

        Item {
            // Phaser
            PlacedKnobMapping {
                legend: "Wet"
                mapping.knobNumber: 1
                mapping.parameterName: "PHA1_WET"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                legend: "Rate"
                mapping.knobNumber: 4
                mapping.parameterName: "PHA1_RATE"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Feedback"
                mapping.knobNumber: 5
                mapping.parameterName: "PHA1_FEEDB"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Daft"
                mapping.knobNumber: 7
                mapping.parameterName: "PHA1_DAFT"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
        }

        Item {
            // Delay
            PlacedKnobMapping {
                legend: "Wet"
                mapping.knobNumber: 1
                mapping.parameterName: "DEL1_WET"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                legend: "Delay"
                mapping.knobNumber: 4
                mapping.parameterName: "DEL1_DELAY"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: {
                        if (delayBPM.value == 0) {
                            return parent.value.toFixed(2) + "s"
                        }
                        return parent.value.toFixed(2) + "beats"
                    }
                }
                
                // If Delay BPM is zero, this indicates a time in seconds.
                // If Delay BPM is non-zero, this is relative to the BPM value and indicates a time in beats.
            }
            PlacedKnobMapping {
                legend: "Feedback"
                mapping.knobNumber: 5
                mapping.parameterName: "DEL1_FEEDB"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                id: delayBPM
                legend: "Delay BPM"
                mapping.knobNumber: 7
                mapping.parameterName: "DEL1_BPM"
                mapping.min: 0
                mapping.max: 360
                mapping.isInteger: true
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: {
                        if (parent.value == 0)
                            return "Auto";
                        return parent.value;
                    }
                }
            }
        }

        Item {
            // Reverb
            PlacedKnobMapping {
                legend: "Wet"
                mapping.knobNumber: 1
                mapping.parameterName: "REV1_WET"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }

            PlacedKnobMapping {
                legend: "Room"
                mapping.knobNumber: 4
                mapping.parameterName: "REV1_ROOM"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Damp"
                mapping.knobNumber: 5
                mapping.parameterName: "REV1_DAMP"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Feedback"
                mapping.knobNumber: 6
                mapping.parameterName: "REV1_FEEDB"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
            PlacedKnobMapping {
                legend: "Width"
                mapping.knobNumber: 7
                mapping.parameterName: "REV1_WIDTH"
                Text {
                    x: (unitSize - width) / 2
                    y: (unitSize - height) / 2
                    text: (parent.value * 100).toFixed(2) + "%"
                }
            }
        }

        PlacedKnobMapping {
            legend: "Compressor"
            mapping.knobNumber: 1
            mapping.parameterName: "DYN1_COMPRESS"
            mapping.isInteger: true
            Text {
                x: (unitSize - width) / 2
                y: (unitSize - height) / 2
                text: (parent.value == 0) ? "OFF" : "ON"
            }
        }
        PlacedKnobMapping {
            legend: "Limiter"
            mapping.knobNumber: 1
            mapping.parameterName: "DYN1_LIMITER"
            mapping.isInteger: true
            Text {
                x: (unitSize - width) / 2
                y: (unitSize - height) / 2
                text: (parent.value == 0) ? "OFF" : "ON"
            }
        }
    }
}
