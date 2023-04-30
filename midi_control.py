import argparse
from enum import Enum
import os
import sys

from PyQt5.QtCore import QUrl, pyqtSignal, pyqtSlot, QObject, QVariant
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import QQmlEngine, qmlRegisterSingletonType, qmlRegisterType

from qsequencer import QSequencer
from piano_roll import PianoRoll


import rtmidi


# from jalv2_host import JALVHost
from carla_host import CarlaHost

app = QApplication(sys.argv)
app.setApplicationDisplayName("HOST")

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

    @pyqtSlot(str, int, int, result=str)
    def getAudioWaveformImage(self, file_name, output_width, output_height):
        """Compute the waveform image of an audio file.

        Arguments
        ---------
        file_name: str
          The input audio file name
        output_width: int
          The desired output image width
        output_height: int
          The desired output image height
        Returns
        -------
          A temporary filename that stores the audio waveform
        """

        import subprocess
        import tempfile

        fo = tempfile.NamedTemporaryFile(suffix=".png")
        tmp_file = fo.name
        fo.close()

        # first extract the number of frames
        # if frames < width, width must be changed

        c = subprocess.run(
            ["ffprobe", "-i", file_name, "-show_streams"],
            capture_output=True,
        )
        n_frames = 0
        for line in c.stdout.decode("utf-8").split("\n"):
            if line.startswith("duration_ts"):
                n_frames = int(line.split("=")[1])
                break
        if n_frames and n_frames < output_width:
            output_width = n_frames

        subprocess.run(
            [
                "ffmpeg",
                "-i",
                file_name,
                "-filter_complex",
                "showwavespic=s={}x{}:colors=black".format(output_width, output_height),
                tmp_file,
            ],
            capture_output=True,
        )
        return tmp_file

    @pyqtSlot(int, result=str)
    def midiNoteName(self, note):
        name_en = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        # name_fr = ["Do", "Do#", "Ré", "Ré#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]
        return "{} {}".format(name_en[note % 12], (note // 12) - 1)


class StubHost(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__next_id = 0

        self._volumes = {}

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        # print(">>> addInstance", lv2_name)
        lv2_id = "stub{}".format(self.__next_id)
        self.__next_id += 1
        return lv2_id

    @pyqtSlot(str, str, float)
    def setParameterValue(self, lv2_id, parameter_name, value):
        # print(">>> setParameterValue", lv2_id, parameter_name, value)
        pass

    @pyqtSlot(str, str, result=float)
    def getParameterValue(self, lv2_id, parameter_name):
        import random

        v = random.random()
        # print(">>> getParameterValue", lv2_id, parameter_name, v)
        return v

    @pyqtSlot(str, int, int)
    def noteOn(self, lv2_id, note, velocity):
        print(">>> Note ON", lv2_id, note, velocity)

    @pyqtSlot(str, int)
    def noteOff(self, lv2_id, note):
        print(">>> Note OFF", lv2_id, note)

    @pyqtSlot(str, int)
    def set_program(self, lv2_id, program_id):
        pass

    @pyqtSlot(str, str, str, result=str)
    def custom_data(self, lv2_id, data_type, data_id):
        pass

    @pyqtSlot(str, str, str, str)
    def set_custom_data(self, lv2_id, data_type, data_id, data_value):
        pass

    @pyqtSlot(str, str, str, int)
    def set_custom_int_data(self, lv2_id, data_type, data_id, data_value):
        pass

    @pyqtSlot(str, result=str)
    @pyqtSlot(str, bool, result=str)
    def save_state(self, lv2_id, convert_xml_to_json=False):
        return ""

    @pyqtSlot(str, str)
    @pyqtSlot(str, str, bool)
    def load_state(self, lv2_id, state, convert_json_to_xml=False):
        pass

    @pyqtSlot(str, result=list)
    def programs(self, lv2_id):
        return []

    @pyqtSlot(str, result=float)
    def getVolume(self, lv2_id):
        return self._volumes.get(lv2_id, 0.0)

    @pyqtSlot(str, float)
    def setVolume(self, lv2_id, volume):
        self._volumes[lv2_id] = volume


class MidiAPI(Enum):
    JACK = rtmidi.API_UNIX_JACK
    ALSA = rtmidi.API_LINUX_ALSA


class Midi(QObject):
    midiReceived = pyqtSignal(QVariant, arguments=["message"])

    def __init__(self, api: MidiAPI, dev_pattern: str = None):
        super().__init__(None)
        self.__midi_in = rtmidi.MidiIn(api, name="Midi control in")
        self.__midi_out = rtmidi.MidiOut(api, name="Midi control out")

        if dev_pattern:
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
        else:
            self.__port_in = self.__midi_in.open_virtual_port("Midi Control in")
            self.__port_out = self.__midi_out.open_virtual_port("Midi Control out")

        self.__port_in.ignore_types(sysex=False)
        self.__port_in.set_callback(self.__on_midi_msg)

        self.__received_message = None
        self.__debug = False

    def set_debug(self, debug):
        self.__debug = debug

    def __to_hex(self, msg):
        return " ".join(["%02x" % c for c in msg])

    def __on_midi_msg(self, event, data=None):
        self.__received_message = event
        msg, ts = event
        if self.__debug:
            print("MIDI Received", self.__to_hex(msg))
        self.midiReceived.emit(msg)

    @pyqtSlot(QVariant)
    def send_message(self, msg):
        if self.__debug:
            print("MIDI Send    ", self.__to_hex(msg))
        self.__port_out.send_message(msg)

    @pyqtSlot(result=QVariant)
    def receive_message(self):
        while not self.__received_message:
            pass
        msg = list(self.__received_message)
        self.__received_message = None
        return msg


parser = argparse.ArgumentParser(description="MIDI-controlled audio station.")
parser.add_argument("--host-stub", action="store_true", help="Stub LV2 host")
parser.add_argument("--dev", action="store", help="MIDI device to use (pattern)")

args = parser.parse_args()

if args.host_stub:
    lv2Host = StubHost()
else:
    # lv2Host = JALVHost()
    lv2Host = CarlaHost("/usr/local")

qmlRegisterSingletonType(
    Utils, "Utils", 1, 0, "Utils", lambda engine, script_engine: Utils()
)
qmlRegisterType(PianoRoll, "PianoRoll", 1, 0, "PianoRoll")

view = QQuickView()
view.setResizeMode(QQuickView.SizeViewToRootObject)
# view.setResizeMode(QQuickView.SizeRootObjectToView)

view.rootContext().setContextProperty("lv2Host", lv2Host)

midi = Midi(rtmidi.API_LINUX_ALSA, args.dev)
view.rootContext().setContextProperty("midi", midi)

sequencer = QSequencer()
view.rootContext().setContextProperty("gSequencer", sequencer)

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, "boards/arturia_minilab_mk2/main.qml")
view.setSource(QUrl.fromLocalFile(qml_file))
view.engine().quit.connect(app.quit)
view.show()

app.exec_()
