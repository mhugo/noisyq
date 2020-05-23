from PyQt5.QtCore import (
    pyqtSlot, QObject, 
)

from rtmidi.midiutil import open_midioutput
import rtmidi

import os
import sys

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
        

