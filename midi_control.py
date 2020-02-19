from PyQt5.QtCore import QUrl, pyqtSignal, pyqtProperty, pyqtSlot, QObject, QTimer
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickItem, QQuickView

from PyQt5.QtQml import qmlRegisterType, QQmlEngine, QQmlComponent

from rtmidi.midiutil import open_midiinput, open_midioutput
import rtmidi

from jalv_wrapper import JALVInstance

import json

import sys
import os

# TODO
# Replace JALV by mod-host to support presets
#  - can be used for a load / save state

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

class MidiOut:
    def __init__(self, jack_name):
        self.__midi_out, _ = open_midioutput(api=rtmidi.API_UNIX_JACK, use_virtual=True, client_name=jack_name)

        # timer for note play
        self.__timer = QTimer()
        self.__timer.setSingleShot(True)
        
    def note_on(self, channel, note, velocity):
        self.__midi_out.send_message([0x90+channel, note, velocity])

    def note_off(self, channel, note):
        self.__midi_out.send_message([0x80+channel, note, 0])

    def note(self, channel, note, velocity, duration):
        # note_on, then pause, then note_off
        self.note_on(channel, note, velocity)
        self.__timer.setInterval(duration)
        self.__timer.timeout.connect(lambda c=channel, n=note: \
                                     self.note_off(c, n))
        self.__timer.start()

class MultipleMidiOut (QQuickItem):
    def __init__(self, parent = None):
        QQuickItem.__init__(self, parent)

        self.__ports = []
        self.__midi_outs = []

        # timer for note play
        self.__timer = QTimer(self)
        self.__timer.setSingleShot(True)

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

    def note(self, port_number, channel, note, velocity, duration):
        # note_on, then pause, then note_off
        self.note_on(port_number, channel, note, velocity)
        self.__timer.timeout.connect(lambda p=port_number, c=channel, n=note: \
                                     self.note_off(p, c, n))
        self.__timer.start()

    @pyqtSlot(int, int, int)
    def note_off(self, port_number, channel, note):
        self.__midi_outs[port_number].send_message([0x80+channel, note, 0])

    @pyqtSlot(int, int, int, int)
    def cc(self, port_number, channel, cc, value):
        self.__midi_outs[port_number].send_message([0xB0+channel, cc, value])
        
    ports = pyqtProperty(list, getPorts, setPorts)

"""
lv2_instances = {
    "Helm 1" : JALVInstance("http://tytel.org/helm", "Helm 1"),
    "Helm 2" : JALVInstance("http://tytel.org/helm", "Helm 2")
}
"""

voices = [
    (MidiOut("midi_out1"), JALVInstance("http://tytel.org/helm", "Helm 1")),
    (MidiOut("midi_out2"), JALVInstance("http://tytel.org/helm", "Helm 2"))
]

class Step:
    def __init__(self, note, velocity, duration):
        self.note = note
        self.velocity = velocity
        self.duration = duration
    
class Sequencer(QObject):

    def __init__(self, n_steps = 16):
        super().__init__()
        self.__n_steps = 16
        # sequence of Step|None
        self.__steps = []
        for voice in range(2):
            self.__steps.append([None] * n_steps)

    def step(self, voice, step_n):
        return self.__steps[voice][step_n]

    @pyqtSlot(int, int, int, int, int)
    def set_step(self, voice, step_n, note, velocity, duration_ms):
        print("** voice ", voice, " step ", step_n)
        self.__steps[voice][step_n] = Step(note, velocity, duration_ms)

    @pyqtSlot(int, int)
    def unset_step(self, voice, step_n):
        self.__steps[voice][step_n] = None

    @pyqtSlot(int)
    def play_step(self, step_n):
        for voice in range(len(self.__steps)):
            step = self.__steps[voice][step_n]
            if step is not None:
                print("**", "step", step_n, "voice", voice, "note", step.note, "duration", step.duration, "velocity", step.velocity)
                voices[voice][0].note(1, step.note, step.velocity, step.duration)

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

        # LV2 instance
        self.__instance_name = None
        self.__voice = None

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

    def __find_lv2_instance_name(self, item):
        instance_name = item.property("lv2InstanceName")
        if instance_name:
            return instance_name
        if item.parent():
            return self.__find_lv2_instance_name(item.parent())
        return None

    def _find_lv2_instance_name(self):
        if self.__instance_name is None:
            self.__instance_name = self.__find_lv2_instance_name(self)

    def instance_name(self):
        return self.__instance_name

    def __find_voice(self, item):
        voice = item.property("voice")
        if voice is not None:
            return voice
        if item.parent():
            return self.__find_voice(item.parent())
        return None

    def _find_voice(self):
        if self.__voice is None:
            self.__voice = self.__find_voice(self)

    def voice(self):
        return self.__voice

    def _property_to_parameter(self, value):
        """Convert a value of the QItem's property into an LV2 parameter"""
        return (value - self.__property_min) / (self.__property_max - self.__property_min) \
            * (self.__parameter_max - self.__parameter_min) \
            + self.__parameter_min

    def _parameter_to_property(self, value):
        """Convert the value of an LV2 parameter into a QItem's property value"""
        return (value - self.__parameter_min) \
            / (self.__parameter_max - self.__parameter_min) \
            * (self.__property_max - self.__property_min) \
            + self.__property_min

    def get_parameter(self):
        return self._property_to_parameter(self.__parent.property(self.__property_name))

    def set_parameter(self, value):
        if value is not None:
            self.__parent.setProperty(self.__property_name, self._parameter_to_property(value))

    def install(self):
        """Install a binding between a widget and an LV2 parameter.

        Thanks to this function, it is possible to bind a widget internal state value to an LV2 parameter.

        When called, it will first sets the object's internal state to the current value of the LV2 parameter.

        Then a callback is installed to synchronize the LV2 parameter value with the object's internal value.

        The object's internal value is represented by:
        - a property that represents the current value
        - a signal that is triggered when the object's internal state changes

        """
        self._find_voice()
        instance = voices[self.voice()][1]

        # We are going to install a signal connection from Python
        # on a C++ object.
        # In order to make sure the Python instance do not get erased, we store a reference
        self.__parent = self.parent()

        # Get the current parameter value
        # and modify the corresponding property
        current_value = instance.get_control(self.__parameter_name)
        if current_value is not None:
            self.__parent.setProperty(self.__property_name, self._parameter_to_property(current_value))

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
            instance.set_control(binding.parameterName, binding._property_to_parameter(obj.property(binding.propertyName)))

        sig.connect(lambda b=self, i=instance, o=self.__parent: _set_control(b, i, o))

PARAMETERS_FILE = ".midi_controls.presets"
app = QApplication(sys.argv)

#print(qmlRegisterType(MidiIn, 'Midi', 1, 0, 'MidiIn'))
print(qmlRegisterType(MultipleMidiOut, 'Midi', 1, 0, 'MidiOut'))
qmlRegisterType(BindingDeclaration, 'Binding', 1, 0, 'BindingDeclaration')

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'app.qml')

sequencer = Sequencer()

view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.rootContext().setContextProperty("sequencer", sequencer)
view.setSource(QUrl.fromLocalFile(qml_file))
view.engine().quit.connect(app.quit)
#view.rootObject().noteOn.connect(lambda v, n: voices[v][0].note_on(1, n, 64))
view.rootObject().noteOn.connect(lambda v, n: voices[v][0].note(1, n, 64, 500))
view.rootObject().noteOff.connect(lambda v, n: voices[v][0].note_off(1, n))

for binding in view.findChildren(BindingDeclaration):
    binding.install()

# TODO: load/save using BindingDeclaration
    
# Load parameters, if any
if os.path.exists(PARAMETERS_FILE):
    with open(PARAMETERS_FILE, "r") as fi:
        params = json.load(fi)

    for binding in view.findChildren(BindingDeclaration):
        v = params[str(binding.voice())].get(binding.parameterName, None)
        binding.set_parameter(v)

view.show()
res = app.exec_()

# Save parameters
params = {
    "__version__" : 1
}
for voice, (midi_out, instance) in enumerate(voices):
    params[str(voice)] = instance.read_controls()

with open(PARAMETERS_FILE, "w") as fo:
    json.dump(params, fo)

sys.exit(res)
