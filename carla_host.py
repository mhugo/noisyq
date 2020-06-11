from PyQt5.QtCore import (
    pyqtSlot, QObject, 
)

from rtmidi.midiutil import open_midioutput
import rtmidi

import os
import sys

import xml.etree.ElementTree as ET
import json

class CarlaHost(QObject):
    class Instance:
        def __init__(self):
            self.uri = ""
            self.id = 0
            # name -> Parameter
            self.parameters = {}

    class Parameter:
        def __init__(self):
            self.name = ""
            self.id = 0
        
    def __init__(self, carla_install_path, parent=None):
        super().__init__(parent)

        # initialize Carla
        if carla_install_path is None:
            carla_install_path = "/usr"
        additional_path = os.path.join(carla_install_path, "share/carla/resources")
        if additional_path not in sys.path:
            sys.path.append(additional_path)

        from carla_backend import (
            CarlaHostDLL,
            ENGINE_OPTION_PATH_BINARIES,
        )

        binary_dir = os.path.join(carla_install_path, "bin")
        self.__host = CarlaHostDLL(
            os.path.join(carla_install_path, "lib/carla/libcarla_standalone2.so"),
            False # RTLD_GLOBAL ?
        )
        self.__host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binary_dir)

        if not self.__host.engine_init("JACK", "carla_client"):
            print("Engine failed to initialize, possible reasons:\n%s" % self.__host.get_last_error())
            sys.exit(1)

        self.__next_id = 0

        self.__midi_out, _ = open_midioutput(api=rtmidi.API_UNIX_JACK, use_virtual=True, client_name="midi_out")

        # name -> Instance
        self.__instances = {}

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        from carla_backend import (
            BINARY_NATIVE,
            PLUGIN_LV2,
            PLUGIN_OPTION_USE_CHUNKS
        )

        print(">>> addInstance", lv2_name)
        lv2_id = str(self.__next_id)
        if not self.__host.add_plugin(
                BINARY_NATIVE,
                PLUGIN_LV2,
                "", # filename (?)
                "", # name
                lv2_name, # label
                self.__next_id, #id
                None, # extraPtr
                PLUGIN_OPTION_USE_CHUNKS #options
        ):
            print("Failed to load plugin, possible reasons:\n%s" % self.__host.get_last_error())
            return

        # DEBUG
        # FIXME: SAMPLV1 does not accept very well state restore when UI is shown !!
        #self.__host.show_custom_ui(self.__next_id, True)

        instance = CarlaHost.Instance()
        instance.id = self.__next_id

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
            instance.id,
            instance.parameters[parameter_name].id,
            value
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

    @pyqtSlot(str, int, int)
    def noteOn(self, lv2_id, note, velocity):
        print(">>> Note ON", lv2_id, note, velocity)
        channel = 0
        self.__host.send_midi_note(
            self.__instances[lv2_id].id,
            channel,
            note,
            velocity
        )

    @pyqtSlot(str, int)
    def noteOff(self, lv2_id, note):
        print(">>> Note OFF", lv2_id, note)
        channel = 0
        self.__host.send_midi_note(
            self.__instances[lv2_id].id,
            channel,
            note,
            0
        )

    @pyqtSlot(str, result=list)
    def programs(self, lv2_id):
        id = self.__instances[lv2_id].id
        p = []
        for i in range(self.__host.get_midi_program_count(id)):
            prog = self.__host.get_midi_program_data(id, i)
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
            return fi.read().decode('utf-8')

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
