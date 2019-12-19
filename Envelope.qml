import QtQuick 2.0
import QtCharts 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

ColumnLayout {
    property string title
    id: adsr

    function updateGraph() {
        lineSeries.clear();
        lineSeries.append(0, 0);
        lineSeries.append(attackKnob.value/16.0, 1);
        lineSeries.append(attackKnob.value/16.0 + decayKnob.value/16.0, sustainKnob.value);
        lineSeries.append(2.0, sustainKnob.value);
        lineSeries.append(2.0+releaseKnob.value/16.0, 0);
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
        width: 400
        height: 400
        LineSeries {
            id: lineSeries
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        Knob {
            id: attackKnob
            text: "A"
            onValueChanged: {
                adsr.updateGraph();
            }
        }
        Item { Layout.fillWidth: true }
        Knob {
            id: decayKnob
            text: "D"
            onValueChanged: {
                adsr.updateGraph();
            }
        }
        Item { Layout.fillWidth: true }
        Knob {
            from: 0
            to: 1.0
            id: sustainKnob
            text: "S"
            onValueChanged: {
                adsr.updateGraph();
            }
        }
        Item { Layout.fillWidth: true }
        Knob {
            id: releaseKnob
            text: "R"
            onValueChanged: {
                adsr.updateGraph();
            }
        }
        Item { Layout.fillWidth: true }
    }
}
