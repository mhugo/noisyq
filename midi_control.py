from PyQt5.QtCore import QUrl, pyqtSignal, pyqtProperty, pyqtSlot
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickItem, QQuickView

from PyQt5.QtQml import qmlRegisterType

from rtmidi.midiutil import open_midiinput, open_midioutput
import rtmidi

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
            self.__midi_in, self.__port = open_midiinput(api=rtmidi.API_UNIX_JACK, use_virtual=True)
            self.__midi_in.set_callback(self._on_msg)
    port = pyqtProperty(str, getPort, setPort)

    dataReceived = pyqtSignal([list, float], arguments=["data", "timestamp"])

class MidiOut (QQuickItem):
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
        self.__port = port
        self.__midi_out, self.__port = open_midioutput(api=rtmidi.API_UNIX_JACK, use_virtual=True, client_name=self.__port)

    @pyqtSlot(int, int, int)
    def note_on(self, channel, note, velocity):
        self.__midi_out.send_message([0x90+channel, note, velocity])

    @pyqtSlot(int, int)
    def note_off(self, channel, note):
        self.__midi_out.send_message([0x80+channel, note, 0])
    port = pyqtProperty(str, getPort, setPort)

app = QApplication(sys.argv)

qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn')
qmlRegisterType(MidiOut, 'Midi', 1, 0, 'MidiOut')

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
