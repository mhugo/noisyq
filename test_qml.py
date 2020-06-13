from PyQt5.QtCore import (
    QUrl, pyqtSignal, pyqtSlot, QObject
)
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickView, QQuickItem
from PyQt5.QtQml import QQmlEngine, qmlRegisterSingletonType

import sys

import os

import rtmidi

#from jalv2_host import JALVHost
from carla_host import CarlaHost

app = QApplication(sys.argv)
app.setApplicationDisplayName("HOST")

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'test_menu.qml')

# TODO
# - replace rtmidi with calls to jack via ctypes ?

class Utils(QObject):
    @pyqtSlot(QObject, result=str)
    def objectId(self, obj):
        ctxt = QQmlEngine.contextForObject(obj)
        if ctxt:
            return ctxt.nameForObject(obj)
        return "<nocontext>"

    @pyqtSlot(str, result=str)
    def readFile(self, file_name):
        if not os.path.exists(file_name):
            return ""
        with open(file_name, "r") as fi:
            return fi.read()

    @pyqtSlot(str, str)
    def saveFile(self, file_name, content):
        with open(file_name, "w") as fo:
            fo.write(content)

    @pyqtSlot(QObject, result=list)
    def findChildren(self, item):
        return item.findChildren(QObject)


class StubHost(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__next_id = 0

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        print(">>> addInstance", lv2_name)
        lv2_id = "stub{}".format(self.__next_id)
        self.__next_id += 1
        return lv2_id

    @pyqtSlot(str, str, float)
    def setParameterValue(self, lv2_id, parameter_name, value):
        print(">>> setParameterValue", lv2_id, parameter_name, value)

    @pyqtSlot(str, str, result=float)
    def getParameterValue(self, lv2_id, parameter_name):
        import random
        v = random.random()
        print(">>> getParameterValue", lv2_id, parameter_name, v)
        return v

    @pyqtSlot(str, int, int)
    def noteOn(self, lv2_id, note, velocity):
        print(">>> Note ON", lv2_id, note, velocity)

    @pyqtSlot(str, int)
    def noteOff(self, lv2_id, note):
        print(">>> Note OFF", lv2_id, note)

class MyGear(QObject):
    class Knob:
        def __init__(self):
            self.value = 0.0
            self.is_integer = False
            self.min = 0.0
            self.max = 1

        def increment(self):
            if self.is_integer:
                self.value += 1
            else:
                self.value += (self.max - self.min) * 0.05
            if self.value > self.max:
                self.value = self.max

        def decrement(self):
            if self.is_integer:
                self.value -= 1
            else:
                self.value -= (self.max - self.min) * 0.05
            if self.value < self.min:
                self.value = self.min

    class Pad:
        def __init__(self):
            self.pressed = False
            self.color = "black"
        
    def __init__(self, api, dev_pattern):
        super().__init__(None)
        self.__api = api
        self.__midi_in = rtmidi.MidiIn(api)
        self.__midi_out = rtmidi.MidiOut(api)

        port_in_idx = 0
        port_out_idx = 0
        for i, port in enumerate(self.__midi_in.get_ports()):
            if dev_pattern.lower() in port.lower():
                port_in_idx = i
                break

        for i, port in enumerate(self.__midi_out.get_ports()):
            if dev_pattern.lower() in port.lower():
                port_out_idx = i
                break

        print("Midi in:", self.__midi_in.get_port_name(port_in_idx))
        print("Midi out:", self.__midi_out.get_port_name(port_out_idx))

        self.__port_in = self.__midi_in.open_port(port_in_idx)
        self.__port_out = self.__midi_out.open_port(port_out_idx)
        self.__port_in.ignore_types(sysex=False)
        self.__port_in.set_callback(self.__on_midi_msg)

        self.__received_message = None
        self.__debug = False

        self.__knob = []
        self.__pad = []
        for i in range(16):
            self.__knob.append(MyGear.Knob())
            self.__pad.append(MyGear.Pad())

        # FIXME !!
        # CC numbers for knobs
        self.__knob_cc = [7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
        self.__cc_knob = {cc: k for k, cc in enumerate(self.__knob_cc)}
        # CC numbers for pads
        self.__pad_cc = [23,24,25,26,27,28,29,30,31,64,65,66,67,68,69,70]
        self.__cc_pad = {cc: k for k, cc in enumerate(self.__pad_cc)}

    def set_debug(self, debug):
        self.__debug = debug

    def __to_hex(self, msg):
        return " ".join(["%02x" % c for c in msg])
    def __on_midi_msg(self, event, data=None):
        self.__received_message = event
        msg, ts = event
        if self.__debug:
            print("MIDI Received", self.__to_hex(msg))

        if msg[0] & 0xF0 == 0x90: # NOTE_ON
            self.notePressed.emit(msg[1], msg[2])
        elif msg[0] & 0xF0 == 0x80: # NOTE_OFF
            self.noteReleased.emit(msg[1])
        elif msg[0] & 0xF0 == 0xB0: # CC
            cc = msg[1]
            v = msg[2]
            if cc in self.__cc_knob:
                if v != 0x40:
                    knob = self.__cc_knob[cc]
                    amplitude = v - 0x40
                    self.knobMoved.emit(knob, amplitude)
            elif cc in self.__cc_pad:
                pad = self.__cc_pad[cc]
                if v == 0x7F:
                    self.padPressed.emit(pad)
                else:
                    self.padReleased.emit(pad)
        elif msg[0] == 0xF0 and msg[-1] == 0xF7: # SYSEX
            sysex = msg[1:-1]
            sysex_prefix = [0x00, 0x20, 0x6b, 0x7f, 0x42]
            if sysex == sysex_prefix + [0x02, 0x00, 0x00, 0x10, 0x7F]:
                self.octaveDown.emit()
            elif sysex == sysex_prefix + [0x02, 0x00, 0x00, 0x11, 0x7F]:
                self.octaveUp.emit()

    def send_message(self, msg):
        if self.__debug:
            print("MIDI Send    ", self.__to_hex(msg))
        self.__port_out.send_message(msg)

    def receive_message(self):
        while not self.__received_message:
            pass
        msg = list(self.__received_message)
        self.__received_message = None
        return msg

    padPressed = pyqtSignal(int, arguments=["padNumber"])
    padReleased = pyqtSignal(int, arguments=["padNumber"])
    knobMoved = pyqtSignal(int, float, arguments=["knobNumber", "amount"])
    notePressed = pyqtSignal(int, int, arguments=["note", "velocity"])
    noteReleased = pyqtSignal(int, arguments=["note"])

    octaveUp = pyqtSignal()
    octaveDown = pyqtSignal()

    @pyqtSlot(int, result=float)
    def knobValue(self, knobNumber):
        return self.__knob[knobNumber].value

    @pyqtSlot(int, int)
    def setKnobValue(self, knobNumber, value):
        self.__knob[knobNumber].value = value

    @pyqtSlot(int, float, float)
    def setKnobMinMax(self, knobNumber, min, max):
        self.__knob[knobNumber].min = min
        self.__knob[knobNumber].max = max

    @pyqtSlot(int, bool)
    def setKnobIsInteger(self, knobNumber, isInteger):
        self.__knob[knobNumber].is_integer = isInteger

    @pyqtSlot(int, result=str)
    def padColor(self, padNumber):
        return self.__pad[padNumber].color

    @pyqtSlot(int, str)
    def setPadColor(self, padNumber, color):
        self.__pad[padNumber].color = color

class NullGear(QObject):
    def __init__(self):
        super().__init__(None)

    padPressed = pyqtSignal(int, arguments=["padNumber"])
    padReleased = pyqtSignal(int, arguments=["padNumber"])
    knobMoved = pyqtSignal(int, float, arguments=["knobNumber", "amount"])
    notePressed = pyqtSignal(int, int, arguments=["note", "velocity"])
    noteReleased = pyqtSignal(int, arguments=["note"])

    octaveUp = pyqtSignal()
    octaveDown = pyqtSignal()

    @pyqtSlot(int, result=float)
    def knobValue(self, knobNumber):
        return 0.0

    @pyqtSlot(int, int)
    def setKnobValue(self, knobNumber, value):
        pass

    @pyqtSlot(int, float, float)
    def setKnobMinMax(self, knobNumber, min, max):
        pass

    @pyqtSlot(int, bool)
    def setKnobIsInteger(self, knobNumber, isInteger):
        pass

    @pyqtSlot(int, result=str)
    def padColor(self, padNumber):
        return "white"

    @pyqtSlot(int, str)
    def setPadColor(self, padNumber, color):
        pass
        
    

print(sys.argv)
if "--help" in sys.argv:
    print("Arguments:")
    print("\t--help\tThis help screen")
    print("\t--host-stub\tStub LV2 host")
    sys.exit(0)

if "--host-stub" in sys.argv:
    lv2Host = StubHost()
else:
    #lv2Host = JALVHost()
    lv2Host = CarlaHost("/usr/local")

if "--gear-dev" in sys.argv:
    gear = MyGear(rtmidi.API_LINUX_ALSA, "Arturia")
    gear.set_debug(True)
else:
    gear = NullGear()
    gear = None
        
qmlRegisterSingletonType(Utils, 'Utils', 1, 0, "Utils", lambda engine, script_engine: Utils())

view = QQuickView()
view.setResizeMode(QQuickView.SizeViewToRootObject)
#view.setResizeMode(QQuickView.SizeRootObjectToView)

view.rootContext().setContextProperty("lv2Host", lv2Host)
view.rootContext().setContextProperty("gear", gear)

view.setSource(QUrl.fromLocalFile(qml_file))
view.engine().quit.connect(app.quit)
view.show()

app.exec_()

