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

class MultipleMidiOut (QQuickItem):
    def __init__(self, parent = None):
        QQuickItem.__init__(self, parent)

        self.__ports = []
        self.__midi_outs = []

    def getPorts(self):
        return self.__ports
    def setPorts(self, ports):
        self.__ports = []
        self.__midi_outs = []
        for client_name in ports:
            midi_out, port = open_midioutput(api=rtmidi.API_UNIX_JACK, use_virtual=True, client_name=client_name)
            self.__midi_outs.append(midi_out)
            self.__ports.append(port)

    @pyqtSlot(int, int, int, int)
    def note_on(self, port_number, channel, note, velocity):
        self.__midi_outs[port_number].send_message([0x90+channel, note, velocity])

    @pyqtSlot(int, int, int)
    def note_off(self, port_number, channel, note):
        self.__midi_outs[port_number].send_message([0x80+channel, note, 0])

    ports = pyqtProperty(list, getPorts, setPorts)

app = QApplication(sys.argv)

qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn')
qmlRegisterType(MultipleMidiOut, 'Midi', 1, 0, 'MidiOut')

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
