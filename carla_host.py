import json
import os
import sys
from typing import Any, Dict, List, Optional
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

import jack
from PyQt5.QtCore import pyqtSlot, QObject, QCoreApplication, QVariant


class JackClient:
    __slots__ = ["name", "midi_in", "audio_out"]

    def __init__(self, name):
        self.name: str = name
        self.midi_in: jack.Port = None
        self.audio_out: List[jack.Port] = [None, None]

    def __repr__(self):
        return "<JackClient midi_in: {}, left_out: {}, right_out: {}>".format(
            self.midi_in, self.audio_out[0], self.audio_out[1]
        )


# Active parameter, boolean type.
# Default is 'false'.
PARAMETER_ACTIVE = -2

# Volume parameter.
# Range 0.0...1.27; default is 1.0.
PARAMETER_VOLUME = -4

# Mono Panning parameter.
# Range -1.0...1.0; default is 0.0.
PARAMETER_PANNING = -7

# Stereo Balance-Left parameter.
# Range -1.0...1.0; default is -1.0.
PARAMETER_BALANCE_LEFT = -5

# Stereo Balance-Right parameter.
# Range -1.0...1.0; default is 1.0.
PARAMETER_BALANCE_RIGHT = -6


@dataclass
class Preset:
    name: str
    parameters: Dict[str, Any]


@dataclass
class PresetBank:
    name: str
    presets: Dict[str, Preset]


def load_lv2_presets() -> Dict[str, Dict[str, PresetBank]]:
    import rdflib
    from rdflib import RDF, RDFS, Namespace

    pset = Namespace("http://lv2plug.in/ns/ext/presets#")
    lv2 = Namespace("http://lv2plug.in/ns/lv2core#")

    # Reload all LV2 presets from disk
    lv2_path = Path.home() / ".lv2"

    sub_folders = [f.path for f in os.scandir(lv2_path) if f.is_dir()]
    g = rdflib.Graph()
    for sub_folder in sub_folders:
        manifest = Path(sub_folder) / "manifest.ttl"
        if not os.path.exists(manifest):
            continue
        g.parse(manifest)

    # plugin uri => bank name => PresetBank
    presets: Dict[str, Dict[str, PresetBank]] = {}
    for bank in g.subjects(RDF.type, pset.bank):
        plugin_uri = str(g.value(bank, lv2.appliesTo))
        bank_name = str(g.value(bank, RDFS.label))

        bank_presets = {}
        for preset in g.subjects(pset.bank, bank):
            # load preset definition
            p = rdflib.Graph()
            p.parse(g.value(preset, RDFS.seeAlso))
            preset_name = str(p.value(preset, RDFS.label))
            ports = p.objects(preset, lv2.port)
            parameters = {}
            for port in ports:
                symbol = str(p.value(port, lv2.symbol))
                value = p.value(port, pset.value).toPython()
                parameters[symbol] = value
            bank_presets[preset_name] = Preset(preset_name, parameters)
            print("Loaded", plugin_uri, bank_name, preset_name)

        presets.setdefault(plugin_uri, {}).setdefault(
            bank_name, PresetBank(bank_name, bank_presets)
        )

    return presets


def load_presets():
    """Load presets from cache if it exists, or load them from disk"""
    import pickle

    presets_cache_file = Path("presets_cache.bin")
    if os.path.exists(presets_cache_file):
        with open(presets_cache_file, "rb") as f:
            print("** load lv2 presets from cache")
            return pickle.load(f)

    presets = load_lv2_presets()
    with open(presets_cache_file, "wb") as fo:
        pickle.dump(presets, fo)

    return presets


class CarlaHost(QObject):
    class Instance:
        def __init__(self):
            self.uri = ""
            self.id = 0
            # name -> Parameter
            self.parameters = {}

            self.presets: Dict[str, PresetBank] = {}

    class Parameter:
        def __init__(self):
            self.name = ""
            self.id = 0

    def __init__(self, carla_install_path, parent=None):
        super().__init__(parent)

        self.__presets = load_presets()

        # initialize Carla
        if carla_install_path is None:
            carla_install_path = "/usr"
        additional_path = os.path.join(carla_install_path, "share/carla/resources")
        if additional_path not in sys.path:
            sys.path.append(additional_path)

        from carla_backend import (
            CarlaHostDLL,
            ENGINE_OPTION_PATH_BINARIES,
            ENGINE_OPTION_PROCESS_MODE,
            ENGINE_PROCESS_MODE_SINGLE_CLIENT,
        )

        binary_dir = os.path.join(carla_install_path, "bin")
        self.__host = CarlaHostDLL(
            os.path.join(carla_install_path, "lib/carla/libcarla_standalone2.so"),
            False,  # RTLD_GLOBAL ?
        )
        self.__host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binary_dir)
        # In this mode, each plugin is visible in Jack, no patchbay involved
        self.__host.set_engine_option(
            ENGINE_OPTION_PROCESS_MODE, ENGINE_PROCESS_MODE_SINGLE_CLIENT, ""
        )

        # A jack client to look for registered ports
        self.__jack = jack.Client("MIDI control")

        # Look for system output
        out_ports = self.__jack.get_ports(
            is_audio=True, is_input=True, is_physical=True
        )
        if len(out_ports) == 2:
            self.__system_audio_out = out_ports
        else:
            raise RuntimeError("Cannot find system output audio ports !")

        if not self.__host.engine_init("JACK", "MIDI control host"):
            print(
                "Engine failed to initialize, possible reasons:\n%s"
                % self.__host.get_last_error()
            )
            sys.exit(1)

        self.__next_id = 0

        self.__jack.set_port_registration_callback(self.on_port_register)
        self.__last_jack_client: Optional[JackClient] = None
        self.__jack.activate()

        # name -> Instance
        self.__instances = {}

        self.__solo: Optional[str] = None
        self.__mute_state: Dict[str, bool] = {}

    def on_port_register(self, port, register):
        client_name, port_name = port.shortname.split(":")
        if self.__last_jack_client is None:
            self.__last_jack_client = JackClient(client_name)
        if port.is_input and port.is_midi and self.__last_jack_client.midi_in is None:
            self.__last_jack_client.midi_in = port
        if port.is_output and port.is_audio:
            if self.__last_jack_client.audio_out[0] is None:
                self.__last_jack_client.audio_out[0] = port
            elif self.__last_jack_client.audio_out[1] is None:
                self.__last_jack_client.audio_out[1] = port

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        if lv2_name.endswith(".sf2") or lv2_name.endswith(".sfz"):
            return self.addSoundFont(lv2_name)
        from carla_backend import BINARY_NATIVE, PLUGIN_LV2, PLUGIN_OPTION_USE_CHUNKS

        print(">>> addInstance", lv2_name)
        lv2_id = str(self.__next_id)
        if not self.__host.add_plugin(
            BINARY_NATIVE,
            PLUGIN_LV2,
            "",  # filename (?)
            "",  # name
            lv2_name,  # label
            self.__next_id,  # id
            None,  # extraPtr
            PLUGIN_OPTION_USE_CHUNKS,  # options
        ):
            print(
                "Failed to load plugin, possible reasons:\n%s"
                % self.__host.get_last_error()
            )
            return

        # on_port_registered should have been called
        # and midi / audio ports for the new plugin collected
        # We can now autoconnect
        if self.__last_jack_client.audio_out[1] is None:
            # mono output
            self.__jack.connect(
                self.__last_jack_client.audio_out[0], self.__system_audio_out[0]
            )
            self.__jack.connect(
                self.__last_jack_client.audio_out[0], self.__system_audio_out[1]
            )
        else:
            # stereo output
            for i in range(2):
                self.__jack.connect(
                    self.__last_jack_client.audio_out[i], self.__system_audio_out[i]
                )
        self.__last_jack_client = None

        # DEBUG
        # FIXME: SAMPLV1 does not accept very well state restore when UI is shown !!
        # self.__host.show_custom_ui(self.__next_id, True)

        instance = CarlaHost.Instance()
        instance.id = self.__next_id
        instance.uri = lv2_name
        instance.presets = self.__presets.get(lv2_name, {})

        # collect parameters id
        pcount = self.__host.get_parameter_count_info(self.__next_id)
        for i in range(pcount["ins"]):
            pinfo = self.__host.get_parameter_info(self.__next_id, i)
            p = CarlaHost.Parameter()
            p.id = i
            p.name = pinfo["symbol"]
            instance.parameters[p.name] = p

        self.__instances[lv2_id] = instance

        self.__next_id += 1
        return lv2_id

    @pyqtSlot(str, result=str)
    def addSoundFont(self, filename: str):
        from carla_backend import (
            BINARY_NATIVE,
            PLUGIN_SF2,
            PLUGIN_SFZ,
            PLUGIN_OPTION_SEND_PROGRAM_CHANGES,
        )

        print(">>> addSoundFont", filename)
        lv2_id = str(self.__next_id)
        if not self.__host.add_plugin(
            BINARY_NATIVE,
            PLUGIN_SF2 if filename.endswith(".sf2") else PLUGIN_SFZ,
            filename,
            "name",  # name
            "label",  # label
            self.__next_id,  # id
            None,  # extraPtr
            PLUGIN_OPTION_SEND_PROGRAM_CHANGES,  # options
        ):
            print(
                "Failed to load sound font, possible reasons:\n%s"
                % self.__host.get_last_error()
            )
            return

        # on_port_registered should have been called
        # and midi / audio ports for the new plugin collected
        # We can now autoconnect
        assert self.__last_jack_client is not None
        for i in range(2):
            self.__jack.connect(
                self.__last_jack_client.audio_out[i], self.__system_audio_out[i]
            )
        self.__last_jack_client = None

        instance = CarlaHost.Instance()
        instance.id = self.__next_id
        instance.uri = filename

        # collect parameters id
        pcount = self.__host.get_parameter_count_info(self.__next_id)
        for i in range(pcount["ins"]):
            pinfo = self.__host.get_parameter_info(self.__next_id, i)
            p = CarlaHost.Parameter()
            p.id = i
            p.name = pinfo["symbol"]
            instance.parameters[p.name] = p

        self.__instances[lv2_id] = instance

        self.__next_id += 1

        return lv2_id

    @pyqtSlot(str, str, float)
    def setParameterValue(self, lv2_id, parameter_name, value):
        instance = self.__instances[lv2_id]
        print(">>> setParameterValue", lv2_id, parameter_name, value)
        self.__host.set_parameter_value(
            instance.id, instance.parameters[parameter_name].id, value
        )

    @pyqtSlot(str, str, result=float)
    def getParameterValue(self, lv2_id, parameter_name):
        instance = self.__instances[lv2_id]
        value = self.__host.get_current_parameter_value(
            instance.id,
            instance.parameters[parameter_name].id,
        )
        print(">>> getParameterValue", lv2_id, parameter_name, value)
        return value

    @pyqtSlot(str, result=float)
    def getVolume(self, lv2_id):
        instance = self.__instances[lv2_id]
        return self.__host.get_internal_parameter_value(instance.id, PARAMETER_VOLUME)

    @pyqtSlot(str, float)
    def setVolume(self, lv2_id, volume):
        instance = self.__instances[lv2_id]
        return self.__host.set_volume(instance.id, volume)

    @pyqtSlot(str, result=float)
    def getPanning(self, lv2_id):
        instance = self.__instances[lv2_id]
        left = self.__host.get_internal_parameter_value(
            instance.id, PARAMETER_BALANCE_LEFT
        )
        right = self.__host.get_internal_parameter_value(
            instance.id, PARAMETER_BALANCE_RIGHT
        )
        panning = (right + left) / 2.0
        return panning

    @pyqtSlot(str, float)
    def setPanning(self, lv2_id, panning):
        instance = self.__instances[lv2_id]
        self.__host.set_balance_left(instance.id, panning)
        return self.__host.set_balance_right(instance.id, panning)

    @pyqtSlot(str, result=bool)
    def getMuted(self, lv2_id):
        instance = self.__instances[lv2_id]
        return not self.__host.get_internal_parameter_value(
            instance.id, PARAMETER_ACTIVE
        )

    @pyqtSlot(str, bool)
    def setMuted(self, lv2_id, muted):
        instance = self.__instances[lv2_id]
        return self.__host.set_active(instance.id, not muted)

    @pyqtSlot(str, result=bool)
    def isSolo(self, lv2_id):
        return self.__solo == lv2_id

    @pyqtSlot(str)
    def setSolo(self, lv2_id):
        print("setSolo", lv2_id)
        if self.__solo is None:
            # save mute states
            self.__mute_state = {}
            for id, instance in self.__instances.items():
                self.__mute_state[id] = not self.__host.get_internal_parameter_value(
                    instance.id, PARAMETER_ACTIVE
                )

        self.__solo = lv2_id

        # mute everything except the solo voice
        for id, instance in self.__instances.items():
            print("set_active", instance.id, id, id == lv2_id)
            self.__host.set_active(instance.id, id == lv2_id)

    @pyqtSlot(str)
    def unsetSolo(self, lv2_id):
        # restore mute states
        for lv2_id, muted in self.__mute_state.items():
            self.setMuted(lv2_id, muted)
        self.__solo = None

    @pyqtSlot(str, int, int)
    def noteOn(self, lv2_id, note, velocity):
        print(">>> Note ON", lv2_id, note, velocity)
        channel = 0
        self.__host.send_midi_note(self.__instances[lv2_id].id, channel, note, velocity)

    @pyqtSlot(str, int)
    def noteOff(self, lv2_id, note):
        print(">>> Note OFF", lv2_id, note)
        channel = 0
        self.__host.send_midi_note(self.__instances[lv2_id].id, channel, note, 0)

    @pyqtSlot(str, result=list)
    def presets(self, lv2_id):
        presets = self.__instances[lv2_id].presets
        return [
            {"bank": bank_name, "presets": list(bank.presets.keys())}
            for bank_name, bank in presets.items()
        ]

    @pyqtSlot(str, str, str)
    def setPreset(self, lv2_id, bank_name, preset_name):
        import decimal

        print("** set preset", lv2_id, bank_name, preset_name)
        instance = self.__instances[lv2_id]
        presets = instance.presets
        bank = presets.get(bank_name)
        if not bank:
            return
        preset = bank.presets.get(preset_name)
        if not preset:
            return
        for _ in range(2):
            for parameter, value in preset.parameters.items():
                if parameter in instance.parameters:
                    if isinstance(value, decimal.Decimal):
                        value = float(value)
                    self.__host.set_parameter_value(
                        instance.id, instance.parameters[parameter].id, value
                    )

    @pyqtSlot(str, result=list)
    def programs(self, lv2_id):
        id = self.__instances[lv2_id].id
        print("MIDI program count", self.__host.get_midi_program_count(id))
        print("program count", self.__host.get_program_count(id))
        for i in range(self.__host.get_program_count(id)):
            prog = self.__host.get_program_name(id, i)
            print("prog", prog)
        p = []
        for i in range(self.__host.get_midi_program_count(id)):
            prog = self.__host.get_midi_program_data(id, i)
            print("midi prog", prog)
            p.append(prog)
        return p

    @pyqtSlot(str, int)
    def set_program(self, lv2_id, program_id):
        id = self.__instances[lv2_id].id
        self.__host.set_midi_program(id, program_id)

    @pyqtSlot(str, str, str, result=str)
    def custom_data(self, lv2_id, data_type, data_id):
        id = self.__instances[lv2_id].id
        self.__host.prepare_for_save(id)
        return self.__host.get_custom_data_value(id, data_type, data_id)

    @pyqtSlot(str, str, str, str)
    def set_custom_data(self, lv2_id, data_type, data_id, data_value):
        id = self.__instances[lv2_id].id
        return self.__host.set_custom_data(id, data_type, data_id, data_value)

    @pyqtSlot(str, str, str, int)
    def set_custom_int_data(self, lv2_id, data_type, data_id, data_value):
        import base64
        import struct

        id = self.__instances[lv2_id].id
        d = base64.b64encode(struct.pack("i", data_value)).decode("utf-8")
        return self.__host.set_custom_data(id, data_type, data_id, d)

    @pyqtSlot()
    def idle(self):
        QCoreApplication.processEvents()

    @pyqtSlot(str, result=str)
    @pyqtSlot(str, bool, result=str)
    def save_state(self, lv2_id, convert_xml_to_json=False):
        id = self.__instances[lv2_id].id
        fn = "/tmp/save_state_tmp"
        self.__host.prepare_for_save(id)
        self.__host.save_plugin_state(id, fn)

        def tree_to_python(tree):
            p = {}
            p["tag"] = tree.tag
            if tree.text.strip():
                p["text"] = tree.text.strip()
            if tree.attrib:
                p["attrib"] = dict(tree.attrib)
            children = [tree_to_python(child) for child in tree]
            if children:
                p["children"] = children
            return p

        if convert_xml_to_json:
            tree = ET.parse(fn)
            return json.dumps(tree_to_python(tree.getroot()))
        else:
            fi = open(fn, "rb")
            return fi.read().decode("utf-8")

    @pyqtSlot(str, str)
    @pyqtSlot(str, str, bool)
    def load_state(self, lv2_id, state, convert_json_to_xml=False):
        id = self.__instances[lv2_id].id
        fn = "/tmp/load_state_tmp"

        def python_to_tree(p):
            elt = ET.Element(p["tag"])
            if "text" in p:
                elt.text = p["text"]
            if "attrib" in p:
                elt.attrib = p["attrib"]
            if "children" in p:
                for child in p["children"]:
                    elt.append(python_to_tree(child))
            return elt

        if convert_json_to_xml:
            root = python_to_tree(json.loads(state))
            tree = ET.ElementTree(root)
            tree.write(fn, encoding="utf-8")
        else:
            with open(fn, "wb") as fo:
                fo.write(state.encode("utf-8"))
        self.__host.load_plugin_state(id, fn)

    # FIXME to be tested
    @pyqtSlot(str, list, list)
    def set_state(self, lv2_id, parameter_values, custom_data):
        instance = self.__instances[lv2_id]
        id = instance.id
        fn = "/tmp/load_state_tmp"
        # self.__host.prepare_for_save(id)
        self.__host.save_plugin_state(id, fn)
        with open(fn, "rb") as fi:
            state = fi.read()
        # print(state)

        cdata_map = {}
        for cdata in custom_data:
            cdata_map[cdata["key"]] = cdata

        print("***cdata_map", repr(cdata_map))

        tree = ET.parse(fn)
        root = tree.getroot()
        data = root[1]
        for child in data:
            print(repr(child.tag))
            if child.tag == "CustomData":
                key = child[1]
                print("****key_text", repr(key.text))
                if key.text in cdata_map:
                    data.remove(child)
                    continue

        # add custom data
        for cdata in custom_data:
            cdata_xml = ET.Element("CustomData")
            ctype = ET.Element("Type")
            ctype.text = cdata["type"]
            ckey = ET.Element("Key")
            ckey.text = cdata["key"]
            cvalue = ET.Element("Value")
            cvalue.text = cdata["value"]
            cdata_xml.extend([ctype, ckey, cvalue])
            data.append(cdata_xml)

        state = ET.tostring(root)
        print("***set_state", state)
        with open(fn, "wb") as fo:
            fo.write(state)
        self.__host.load_plugin_state(instance.id, fn)
