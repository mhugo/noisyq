import sys
from signal import signal, SIGINT, SIGTERM
from time import sleep

additional_path = "/usr/local/share/carla/resources"
if additional_path not in sys.path:
    sys.path.append(additional_path)

from carla_backend import (
    CarlaHostDLL,
    ENGINE_OPTION_PATH_BINARIES,
    BINARY_NATIVE,
    PLUGIN_LV2,
    PLUGIN_OPTION_USE_CHUNKS
)

class CarlaObject(object):
    __slots__ = [
        'term'
    ]

gCarla = CarlaObject()
gCarla.term = False

def signalHandler(sig, frame):
    if sig in (SIGINT, SIGTERM):
        gCarla.term = True

binaryDir = "/usr/local/bin"
host = CarlaHostDLL("/usr/local/lib/carla/libcarla_standalone2.so", False)
host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binaryDir)

if not host.engine_init("JACK", "test_carla"):
    print("Engine failed to initialize, possible reasons:\n%s" % host.get_last_error())
    sys.exit(1)

#lv2_uri = "http://tytel.org/helm"
lv2_uri = "http://samplv1.sourceforge.net/lv2"
if not host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, "", "", lv2_uri, 0, None, PLUGIN_OPTION_USE_CHUNKS):
    print("Failed to load plugin, possible reasons:\n%s" % host.get_last_error())
    host.engine_close()
    exit(1)

plugin_info = host.get_plugin_info(0)
print(plugin_info)

pcount = host.get_parameter_count_info(0)
print(pcount)
for i in range(pcount["ins"]):
    pinfo = host.get_parameter_info(0, i)
    print(pinfo)

midip_count = host.get_midi_program_count(0)
for i in range(midip_count):
    print(host.get_midi_program_name(0, i))
    print(host.get_midi_program_data(0, i))
print(midip_count)

host.show_custom_ui(0, True)

host.save_plugin_state(0, "/tmp/state")

signal(SIGINT,  signalHandler)
signal(SIGTERM, signalHandler)

while host.is_engine_running() and not gCarla.term:
    host.engine_idle()
    sleep(1)
    # need to be called before get_custom_data
    host.prepare_for_save(0)
    cdata_count = host.get_custom_data_count(0)
    for i in range(cdata_count):
        print(host.get_custom_data(0, i))
    #host.save_plugin_state(0, "/tmp/state")

if not gCarla.term:
    print("Engine closed abruptely")

if not host.engine_close():
    print("Engine failed to close, possible reasons:\n%s" % host.get_last_error())
    exit(1)
