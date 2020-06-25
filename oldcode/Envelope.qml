import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    property string title
    id: adsr

    property real attack
    property real sustain
    property real decay
    property real release

    onAttackChanged : {
        updateGraph();
        attackKnob.value = attack;
    }
    onSustainChanged : {
        updateGraph();
        sustainKnob.value = sustain;
    }
    onDecayChanged : {
        updateGraph();
        decayKnob.value = decay;
    }
    onReleaseChanged : {
        updateGraph();
        releaseKnob.value = release;
    }

    function updateGraph() {
        lineSeries.clear();
        lineSeries.append(0, 0);
        lineSeries.append(attack/16.0, 1);
        lineSeries.append(attack/16.0 + decay/16.0, sustain);
        lineSeries.append(attack/16.0 + decay/16.0 + release/16.0, 0);
        chartView.axes[0].gridVisible = false;
        chartView.axes[0].max = 3.0;
        chartView.axes[0].min = 0.0;
        chartView.axes[1].gridVisible = false;
        chartView.axes[1].max = 1.0;
        chartView.axes[1].min = 0.0;
    }

    Text {
        text: parent.title
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
    }

    ChartView {
        id: chartView
        legend.visible: false
        Layout.fillWidth: true
        theme: ChartView.ChartThemeDark
        width: 200
        height: 200
        LineSeries {
            id: lineSeries
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        ControlFrame {
            text: "A"
            Knob {
                id: attackKnob
                onValueChanged: {
                    adsr.attack = value;
                }
            }
        }
        Item { Layout.fillWidth: true }
        ControlFrame {
            text: "D"
            Knob {
                id: decayKnob
                onValueChanged: {
                    adsr.decay = value;
                }
            }
        }
        Item { Layout.fillWidth: true }
        ControlFrame {
            text: "S"
            Knob {
                from: 0
                to: 1.0
                id: sustainKnob
                onValueChanged: {
                    adsr.sustain = value;
                }
            }
        }
        Item { Layout.fillWidth: true }
        ControlFrame {
            text: "R"
            Knob {
                id: releaseKnob
                onValueChanged: {
                    adsr.release = value;
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
