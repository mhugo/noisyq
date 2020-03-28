from PyQt5.QtCore import (
    QUrl, pyqtSignal, pyqtProperty, pyqtSlot, QObject, QTimer,
    QMetaObject
)
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickItem, QQuickView

from PyQt5.QtQml import (
    qmlRegisterType, QQmlComponent,
    QQmlEngine
)

from rtmidi.midiutil import open_midiinput, open_midioutput
import rtmidi

from jalv_wrapper import JALVInstance

import json

import sys
import os

# Number of tracks
N_TRACKS = 8

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

    def control_change(self, channel, control, value):
        self.__midi_out.send_message([0xB0+channel, control, value])

    def program_change(self, channel, bank, program):
        print("program change", channel, program)
        self.control_change(channel, 32, bank & 0x7f)
        self.control_change(channel, 0, bank >> 7)
        self.__midi_out.send_message([0xC0+channel, program])

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

class Track(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.__plugin = None
        self.__track_number = 0
        self.__midi_out = None
        self.__component = None
        self.__quick_item = None

    def plugin(self):
        return self.__plugin

    def component(self):
        return self.__component

    def track_number(self):
        return self.__track_number

    def midi_out(self):
        return self.__midi_out

    def quick_item(self):
        return self.__quick_item

    def set_quick_item(self, item):
        self.__quick_item = item

    def instantiate_plugin(self, qml_context, qml_url, lv2_url, track_number):
        self.__track_number = track_number
        self.__plugin = JALVInstance(lv2_url, "Plugin {}".format(track_number))
        self.__midi_out = MidiOut("midi_out{}".format(track_number))
        self.__component = QQmlComponent(qml_context.engine(), qml_url)
        self.__quick_item = self.__component.create(qml_context)


class Tracks(QQuickItem):

    PARAMETERS_FILE = ".midi_controls.presets"
    
    PARAMETERS_FILE_VERSION = 3

    def __init__(self, parent):
        super().__init__(parent)

        self.__tracks = []
        for i in range(N_TRACKS):
            self.__tracks.append(Track(self))
        self.__current_track = 0

        self.setFlags(self.flags() | QQuickItem.ItemHasContents)

        blank_component = QQmlComponent(
            view.engine(),
            "BlankTrack.qml"
        )

        self.__blank_item = blank_component.create(
            view.rootContext()
        )
        self.__blank_item.setParentItem(self)

    def __getitem__(self, k):
        return self.__tracks[k]

    def __iter__(self):
        for t in self.__tracks:
            yield t

    current_track_changed = pyqtSignal(int)

    def current_track(self):
        return self.__current_track

    def set_current_track(self, t):
        old_item = self.__tracks[self.__current_track].quick_item()
        if not old_item:
            old_item = self.__blank_item
        old_item.setParentItem(None)
        item = self.__tracks[t].quick_item()
        if not item:
            item = self.__blank_item
        item.setParentItem(self)
        self.__current_track = t
        self.current_track_changed.emit(t)
        self.setImplicitHeight(self.height())
        self.setImplicitWidth(self.width())

    currentTrack = pyqtProperty(int, current_track, set_current_track, notify=current_track_changed)

    @pyqtProperty(QQuickItem)
    def currentItem(self):
        return self.__tracks[self.__current_track].quick_item()

    @pyqtProperty(int)
    def count(self):
        return len(self.__tracks)

    @pyqtSlot(str, str, int, result=QQmlComponent)
    def instantiate_plugin(self, qml_url, lv2_url, track_number):
        old_item = self.__tracks[track_number].quick_item()
        if not old_item:
            old_item = self.__blank_item
        old_item.setParentItem(None)
        self.__tracks[track_number].instantiate_plugin(
            view.rootContext(),
            qml_url,
            lv2_url,
            track_number
        )
        self.__tracks[track_number].quick_item().setParentItem(self)
        # Sets "track" property of the item
        self.__tracks[track_number].quick_item().setProperty("track", track_number)
        self.setImplicitHeight(self.height())
        self.setImplicitWidth(self.width())


    def load_parameters(self):
        print("*** load_parameters")
        params = {}
        if os.path.exists(self.PARAMETERS_FILE):
            with open(self.PARAMETERS_FILE, "r") as fi:
                params = json.load(fi)

            if params["__version__"] == self.PARAMETERS_FILE_VERSION:

                # create tracks
                for n, track in enumerate(params["tracks"]):
                    self.instantiate_plugin(
                        track["qml_url"],
                        track["lv2_url"],
                        n
                    )

                # sequencer state
                sequencer.restore(params["sequencer"])

                self.set_current_track(0)

        return params

    def save_parameters(self):
        params = {
            "__version__" : self.PARAMETERS_FILE_VERSION,
            "sequencer" : sequencer.dump(),
            "tracks" : []
        }
        for track in self.__tracks:
            if track.plugin():
                params["tracks"].append({
                    "lv2_url": track.plugin().lv2_url(),
                    "qml_url": track.component().url().toString(),
                    "controls": track.plugin().read_controls()
                })

        with open(self.PARAMETERS_FILE, "w") as fo:
            json.dump(params, fo)

class Step(QObject):
    def __init__(self, note, velocity, duration):
        super().__init__()
        self.note = note
        self.velocity = velocity
        self.duration = duration

    def dump(self):
        return {
            "note": self.note,
            "velocity": self.velocity,
            "duration": self.duration
        }

def step_restore(dump):
    return Step(
        dump["note"],
        dump["velocity"],
        dump["duration"]
    )
    
class Sequencer(QObject):

    def __init__(self, n_steps = 16):
        super().__init__()
        self.__n_steps = n_steps
        # sequence of Step|None
        self.__steps = []
        for track in range(N_TRACKS):
            self.__steps.append([None] * n_steps)


    @pyqtSlot(int, int, result=Step)
    def step(self, track, step_n):
        return self.__steps[track][step_n]

    @pyqtSlot(int, int, int, int, int)
    def set_step(self, track, step_n, note, velocity, duration_ms):
        self.__steps[track][step_n] = Step(note, velocity, duration_ms)

    @pyqtSlot(int, int)
    def unset_step(self, track, step_n):
        self.__steps[track][step_n] = None

    @pyqtSlot(int)
    def play_step(self, step_n):
        for track in range(tracks.count):
            step = self.__steps[track][step_n]
            if step is not None:
                tracks[track].midi_out().note(1, step.note, step.velocity, step.duration)

    def dump(self):
        return [
            [s.dump() if s is not None else None for s in t]
            for t in self.__steps
        ]

    def restore(self, dump):
        for ti, track in enumerate(dump):
            for si, step in enumerate(track):
                if step is None:
                    self.__steps[ti][si] = None
                else:
                    self.__steps[ti][si] = step_restore(step)

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
        self.__track = None

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

    def __find_track(self, item):
        track = item.property("track")
        if track is not None:
            return track
        if item.parent():
            return self.__find_track(item.parent())
        return None

    def _find_track(self):
        if self.__track is None:
            self.__track = self.__find_track(self)

    def track(self):
        return self.__track

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
        self._find_track()
        instance = tracks[self.track()].plugin()

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

app = QApplication(sys.argv)

qmlRegisterType(MultipleMidiOut, 'Midi', 1, 0, 'MidiOut')
qmlRegisterType(BindingDeclaration, 'Binding', 1, 0, 'BindingDeclaration')
qmlRegisterType(Tracks, 'Tracks', 1, 0, 'Tracks')

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'app.qml')


view = QQuickView()
view.setResizeMode(QQuickView.SizeViewToRootObject)

sequencer = Sequencer()
view.rootContext().setContextProperty("sequencer", sequencer)

view.setSource(QUrl.fromLocalFile(qml_file))
view.engine().quit.connect(app.quit)
view.rootObject().noteOn.connect(lambda v, n: tracks[v].midi_out().note(1, n, 64, 500))
view.rootObject().noteOff.connect(lambda v, n: tracks[v].midi_out().note_off(1, n))
view.rootObject().programChange.connect(lambda v, b, p: tracks[v].midi_out().program_change(1, b, p))

params = None
has_tracks = False
for tracks in view.findChildren(Tracks):
    has_tracks = True
    p = tracks.load_parameters()
    if "tracks" in p:
        params = p["tracks"]
    
if not has_tracks:
    print("No Tracks object defined !")
    sys.exit(1)

# Install bindings and initialize parameters
for n, track in enumerate(tracks):
    if track.quick_item():
        for binding in track.quick_item().findChildren(BindingDeclaration):
            binding.install()
            v = params[n]["controls"].get(binding.parameterName, None)
            binding.set_parameter(v)

view.show()

# FIXME
# Force sequencer state initialization
for seq in view.findChildren(QQuickItem, "sequencer"):
    QMetaObject.invokeMethod(seq, "updateState")

res = app.exec_()

# Save parameters
for tracks in view.findChildren(Tracks):
    tracks.save_parameters()

sys.exit(res)
