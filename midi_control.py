from PyQt5.QtCore import QUrl, pyqtSignal, pyqtProperty, pyqtSlot, QObject
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickItem, QQuickView

from PyQt5.QtQml import qmlRegisterType, QQmlEngine, QQmlComponent

from rtmidi.midiutil import open_midiinput, open_midioutput
import rtmidi

from jalv_wrapper import JALVInstance

import sys
import os

class MidiIn (QQuickItem):
    def __init__(self, parent = None):
        QQuickItem.__init__(self, parent)

        self.__port = None

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

    @pyqtSlot(int, int, int, int)
    def cc(self, port_number, channel, cc, value):
        self.__midi_outs[port_number].send_message([0xB0+channel, cc, value])
        
    ports = pyqtProperty(list, getPorts, setPorts)


lv2_instances = {
    "Helm 1" : JALVInstance("http://tytel.org/helm", "Helm 1"),
    "Helm 2" : JALVInstance("http://tytel.org/helm", "Helm 2")
}

class BindingDeclaration(QQuickItem):
    def __init__(self, parent = None):
        QObject.__init__(self, parent)

        self.__signal_name = ""
        self.__property_name = "value"
        self.__parameter_name = ""
        self.__parameter_min = 0.0
        self.__parameter_max = 1.0
        self.__property_min = 0.0
        self.__property_max = 1.0

        self.__parent = None

    def getSignalName(self):
        return self.__signal_name

    def setSignalName(self, signal_name):
        self.__signal_name = signal_name

    def getPropertyName(self):
        return self.__property_name

    def setPropertyName(self, property_name):
        self.__property_name = property_name

    def getParameterName(self):
        return self.__parameter_name

    def setParameterName(self, parameter_name):
        self.__parameter_name = parameter_name

    def getPropertyMin(self):
        return self.__property_min

    def setPropertyMin(self, property_min):
        self.__property_min = property_min

    def getPropertyMax(self):
        return self.__property_max

    def setPropertyMax(self, property_max):
        self.__property_max = property_max

    def getParameterMin(self):
        return self.__parameter_min

    def setParameterMin(self, parameter_min):
        self.__parameter_min = parameter_min

    def getParameterMax(self):
        return self.__parameter_max

    def setParameterMax(self, parameter_max):
        self.__parameter_max = parameter_max

    signalName = pyqtProperty(str, getSignalName, setSignalName)
    propertyName = pyqtProperty(str, getPropertyName, setPropertyName)
    parameterName = pyqtProperty(str, getParameterName, setParameterName)
    propertyMin = pyqtProperty(float, getPropertyMin, setPropertyMin)
    propertyMax = pyqtProperty(float, getPropertyMax, setPropertyMax)
    parameterMin = pyqtProperty(float, getParameterMin, setParameterMin)
    parameterMax = pyqtProperty(float, getParameterMax, setParameterMax)

    def _find_lv2_instance_name(self, item):
        instance_name = item.property("lv2InstanceName")
        if instance_name:
            return instance_name
        if item.parent():
            return self._find_lv2_instance_name(item.parent())
        return None

    def install(self):
        """Install a binding between a widget and an LV2 parameter.

        Thanks to this function, it is possible to bind a widget internal state value to an LV2 parameter.

        When called, it will first sets the object's internal state to the current value of the LV2 parameter.

        Then a callback is installed to synchronize the LV2 parameter value with the object's internal value.

        The object's internal value is represented by:
        - a property that represents the current value
        - a signal that is triggered when the object's internal state changes

        """
        lv2_instance_name = self._find_lv2_instance_name(self)
        instance = lv2_instances.get(lv2_instance_name)
        if instance is None:
            print("Instance not found: {}".format(lv2_instance_name))
            return

        # We are going to install a signal connection from Python
        # on a C++ object.
        # In order to make sure the Python instance do not get erased, we store a reference
        self.__parent = self.parent()

        # Get the current parameter value
        # and modify the corresponding property
        current_value = instance.get_control(self.__parameter_name)
        self.__parent.setProperty(self.__property_name, current_value)

        # The signal is given by name. Since a signal is represented as an attribute,
        # We call getattr to get the corresponding signal object
        if not self.__signal_name:
            self.__signal_name = self.__property_name + "Changed"
        try:
            sig = getattr(self.__parent, self.__signal_name)
        except AttributeError:
            print("Signal not found: {}".format(self.__signal_name))
            return

        def _set_control(binding, instance, obj):
            instance.set_control(binding.parameterName, (obj.property(binding.propertyName) - binding.propertyMin)
                                 / (binding.propertyMax - binding.propertyMin)
                                 * (binding.parameterMax - binding.parameterMin)
                                 + binding.parameterMin)

        sig.connect(lambda b=self, i=instance, o=self.__parent: _set_control(b, i, o))

app = QApplication(sys.argv)

#print(qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn'))
print(qmlRegisterType(MultipleMidiOut, 'Midi', 1, 0, 'MidiOut'))
qmlRegisterType(BindingDeclaration, 'Binding', 1, 0, 'BindingDeclaration')

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'app.qml')
engine = QQmlEngine()

component = QQmlComponent(engine)

view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile(qml_file))

for binding in view.findChildren(BindingDeclaration):
    binding.install()

view.show()
res = app.exec_()
sys.exit(res)
