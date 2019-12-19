from PyQt5.QtCore import QUrl, pyqtSignal, pyqtProperty, QRect
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickItem, QQuickView

from PyQt5.QtQml import qmlRegisterType

from rtmidi.midiutil import open_midiinput, open_midioutput

import sys
import os

class MidiIn (QQuickItem):
    def __init__(self, parent = None):
        QQuickItem.__init__(self, parent)

        self.__port = None
        print("ctor")

    def _on_msg(self, event, data=None):
        msg, ts = event
        self.dataReceived.emit(msg, ts)

    def getPort(self):
        return self.__port
    def setPort(self, port):
        if self.__port is None:
            self.__midi_in, self.__port = open_midiinput(port)
            self.__midi_in.set_callback(self._on_msg)
    port = pyqtProperty(str, getPort, setPort)

    dataReceived = pyqtSignal([list, float], arguments=["data", "timestamp"])

app = QApplication(sys.argv)

qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn')

view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'app.qml')
view.setSource(QUrl.fromLocalFile(qml_file))

if view.status() == QQuickView.Error:

    sys.exit(-1)

view.show()
res = app.exec_()
del view
sys.exit(res)
