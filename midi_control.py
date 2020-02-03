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

    @pyqtSlot(int, int, int, int)
    def cc(self, port_number, channel, cc, value):
        self.__midi_outs[port_number].send_message([0xB0+channel, cc, value])
        
    ports = pyqtProperty(list, getPorts, setPorts)

class JALVWrapper (QObject):
    def __init__(self, parent = None):
        print("JALVWrapper ctor")
        QObject.__init__(self, parent)

        self.__instance = None

    @pyqtSlot(str, str)
    def setInstance(self, uri, name):
        self.__instance = JALVInstance(uri, name)

    @pyqtSlot(str, float)
    def setControl(self, control_name, value):
        if not self.__instance:
            return
        self.__instance.set_control(control_name, value)

    @pyqtSlot(str, result=float)
    def getControl(self, control_name):
        if not self.__instance:
            return None
        v = self.__instance.get_control(control_name)
        return v

class JALVLV2Binding(QObject):
    def __init__(self, parent=None):
        print("JALVLV2Binding")
        QObject.__init__(self, parent)

        self.__instances = {
            "Helm 1" : JALVInstance("http://tytel.org/helm", "Helm 1"),
            "Helm 2" : JALVInstance("http://tytel.org/helm", "Helm 2")
        }

    @pyqtSlot(QObject, str, str, str, str, float, float, float, float)
    def set(self, obj, obj_signal_name, obj_property_name, lv2_instance_name, lv2_parameter_name,
            obj_min_value, obj_max_value, lv2_min_value, lv2_max_value):
        """Install a binding between a widget and an LV2 parameter.

        Thanks to this function, it is possible to bind a widget internal state value to an LV2 parameter.

        When called, it will first sets the object's internal state to the current value of the LV2 parameter.

        Then a callback is installed to synchronize the LV2 parameter value with the object's internal value.

        The object's internal value is represented by:
        - a property that represents the current value
        - a signal that is triggered when the object's internal state changes

        Parameters
        ==========
        obj: QObject
          The object (usually a widget) to bind
        obj_signal_name: str
          Name of the object' signal that updates the internal value change (e.g. "valueChanged")
        obj_property_name: str
          Name of the object's property that stored the internal value
        lv2_instance_name: str
          Name of the JALV instance
        lv2_parameter_name: str
          Name of the LV2 parameter to bind
        obj_min_value: float
          Minimum value of the object's internal state
        obj_max_value: float
          Maximum value of the object's internal state
        lv2_min_value: float
          Minimum value of the LV2 parameter
        lv2_max_value: float
          Maximum value of the LV2 parameter
        """
        print("lv2_binding_set", obj, obj_signal_name, obj_property_name, lv2_instance_name, lv2_parameter_name,
            obj_min_value, obj_max_value, lv2_min_value, lv2_max_value)
        instance = self.__instances.get(lv2_instance_name)
        if instance is None:
            print("Instance not found: {}".format(lv2_instance_name))
            return
        # Get the current parameter value
        # and modify the corresponding property
        current_value = instance.get_control(lv2_parameter_name)
        print("{} = {}".format(lv2_parameter_name, current_value))
        obj.setProperty(obj_property_name, current_value)

        # The signal is given by name. Since a signal is represented as an attribute,
        # We call getattr to get the corresponding signal object
        try:
            sig = getattr(obj, obj_signal_name)
        except AttributeError:
            print("Signal not found: {}".format(obj_signal_name))
            return

        def _set_control(inst, param_name, value):
            print("inst", inst, "param_name", param_name, "value", value)
            inst.set_control(param_name, value)
            
        sig.connect(lambda :
                    _set_control(instance, lv2_parameter_name,
                                         (obj.property(obj_property_name) - obj_min_value)
                                         / (obj_max_value - obj_min_value)
                                         * (lv2_max_value - lv2_min_value)
                                         + lv2_min_value)
                    )

    
app = QApplication(sys.argv)

print(qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn'))
print(qmlRegisterType(MultipleMidiOut, 'Midi', 1, 0, 'MidiOut'))
#print(qmlRegisterType(JALVWrapperAttachedProperties))
#print(qmlRegisterType(JALVWrapper, 'Midi', 1, 0, 'JALVWrapper',
#                      attachedProperties=JALVWrapperAttachedProperties))

engine = QQmlEngine()

component = QQmlComponent(engine)

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'app.qml')

lv2_binding = JALVLV2Binding()
view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.engine().rootContext().setContextProperty("lv2Binding", lv2_binding)
view.setSource(QUrl.fromLocalFile(qml_file))
view.show()
res = app.exec_()
sys.exit(res)
