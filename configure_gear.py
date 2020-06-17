from rtmidi.midiutil import open_midiinput, open_midioutput
import rtmidi

import time

import argparse

api = rtmidi.API_LINUX_ALSA

parser = argparse.ArgumentParser(description='Configure a MIDI controller.')
parser.add_argument('--alsa', action="store_true",
                    help='Use ALSA MIDI')
parser.add_argument('--jack', action="store_true",
                    help="Use JACK MIDI")
parser.add_argument('--dev', action="store",
                    required=True,
                    help="MIDI device to use (pattern)")

args = parser.parse_args()

if args.alsa:
    api = rtmidi.API_LINUX_ALSA
elif args.jack:
    api = rtmidi.API_UNIX_JACK


class Midi:
    def __init__(self, api, dev_pattern):
        self.__api = api
        self.__midi_in = rtmidi.MidiIn(api)
        self.__midi_out = rtmidi.MidiOut(api)

        port_in_idx = 0
        port_out_idx = 0
        for i, port in enumerate(self.__midi_in.get_ports()):
            if args.dev.lower() in port.lower():
                port_in_idx = i
                break

        for i, port in enumerate(self.__midi_out.get_ports()):
            if args.dev.lower() in port.lower():
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

    def set_debug(self, debug):
        self.__debug = debug

    def __on_midi_msg(self, event, data=None):
        self.__received_message = event
        if self.__debug:
            msg, ts = event
            print("Received", to_hex(msg))

    def send_message(self, msg):
        if self.__debug:
            print("Send    ", to_hex(msg))
        self.__port_out.send_message(msg)

    def receive_message(self):
        while not self.__received_message:
            pass
        msg = list(self.__received_message)
        self.__received_message = None
        return msg

midi = Midi(api, args.dev)

def to_hex(msg):
    return " ".join(["%02x" % c for c in msg])

prefix = [
    0xF0,
    0x00, 0x20, 0x6B, # Arturia
    0x7F, 0x42 #??
]

# Control ID
KNOB_1 = 0x30
KNOB_1_BUTTON = 0x31
KNOB_1_SHIFT = 0x32
KNOB_9 = 0x33
KNOB_9_BUTTON = 0x34
KNOB_9_SHIFT = 0x35
KNOB_2 = 0x01
KNOB_3 = 0x02
KNOB_4 = 0x09
KNOB_5 = 0x0B
KNOB_6 = 0x0C
KNOB_7 = 0x0D
KNOB_8 = 0x0E
KNOB_10 = 0x03
KNOB_11 = 0x04
KNOB_12 = 0x0A
KNOB_13 = 0x05
KNOB_14 = 0x06
KNOB_15 = 0x07
KNOB_16 = 0x08

knob_id = [
    KNOB_1,
    KNOB_2,
    KNOB_3,
    KNOB_4,
    KNOB_5,
    KNOB_6,
    KNOB_7,
    KNOB_8,
    KNOB_9,
    KNOB_10,
    KNOB_11,
    KNOB_12,
    KNOB_13,
    KNOB_14,
    KNOB_15,
    KNOB_16
]

PAD_1 = 0x70
PAD_2 = 0x71
PAD_3 = 0x72
PAD_4 = 0x73
PAD_5 = 0x74
PAD_6 = 0x75
PAD_7 = 0x76
PAD_8 = 0x77
PAD_9 = 0x78
PAD_10 = 0x79
PAD_11 = 0x7A
PAD_12 = 0x7B
PAD_13 = 0x7C
PAD_14 = 0x7D
PAD_15 = 0x7E
PAD_16 = 0x7F

pad_id = [
    PAD_1,
    PAD_2,
    PAD_3,
    PAD_4,
    PAD_5,
    PAD_6,
    PAD_7,
    PAD_8,
    PAD_9,
    PAD_10,
    PAD_11,
    PAD_12,
    PAD_13,
    PAD_14,
    PAD_15,
    PAD_16,
    KNOB_1_BUTTON,
    KNOB_9_BUTTON
]

BTN_OCTAVE_DOWN = 0x10
BTN_OCTAVE_UP = 0x12
BTN_SHIFT = 0x2E
BTN_SWITCH_PADS = 0x2F
BTN_PITCH_BEND = 0x41

GET_SET_VALUE = 0
GET_SET_MODE = 1
GET_SET_CHANNEL = 2
GET_SET_VALUE_2 = 3
GET_SET_VALUE_3 = 4
GET_SET_VALUE_4 = 5
GET_SET_OPTION = 6
GET_SET_COLOR = 0x10
GET_SET_TOGGLE_COLOR = 0x11

# Options for Mode = Control
OPTION_ABSOLUTE = 0
OPTION_RELATIVE_1 = 1
OPTION_RELATIVE_2 = 2
OPTION_RELATIVE_3 = 3

# Options for Mode = Switched (pads)
OPTION_TOGGLE = 0 # toggle button
OPTION_GATE = 1 # normal button

MODE_CONTROL = 1
# ??? = 2
# ??? = 3
MODE_NRPN = 4
# ??? = 5
# ??? = 6

# mode for PADS
MODE_MMC = 7
MODE_SWITCHED = 8
MODE_MIDI_NOTE = 9
# ??? = 10
MODE_PATCH_CHANGE = 11
# ??? = 12
# ??? = 13
# ??? = 14
# ??? = 15
MODE_PITCH_BEND = 16

COLOR_BLACK = 0x00
COLOR_RED = 0x01
COLOR_BLUE = 0x10
COLOR_GREEN = 0x04
COLOR_PURPLE = 0x11
COLOR_CYAN = 0x14
COLOR_YELLOW = 0x05
COLOR_WHITE = 0x7F

def read_control(control, operation):
    midi.send_message(prefix + [
        0x01, # read value
        0x00,
        operation, # operation
        control, # knob 1
        0xF7 # sysex end
    ])
    msg, _ = midi.receive_message()
    return msg[10]

def write_control(control, operation, value):
    midi.send_message(prefix + [
        0x02, # write value
        0x00,
        operation,
        control,
        value,
        0xF7
    ])

# CC numbers for knobs
knob_cc = [7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
# CC numbers for pads
pad_cc = [
    23,24,25,26,27,28,29,30,31, 64,65,66,67,68,69,70,
    71, # knob 1 switch
    72, # knob 9 switch
]

assert len(knob_cc) == 16
    
try:
    # ask sysexid
    midi.send_message([0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7])
    msg, ts = midi.receive_message()

    # set knobs
    for i in range(16):
        write_control(knob_id[i], GET_SET_MODE, MODE_CONTROL)
        # set CC
        write_control(knob_id[i], GET_SET_VALUE_2, knob_cc[i])
        # set relative
        write_control(knob_id[i], GET_SET_OPTION, OPTION_RELATIVE_1)
    time.sleep(0.2)

    for i in range(16):
        mode = read_control(knob_id[i], GET_SET_MODE)
        value = read_control(knob_id[i], GET_SET_VALUE)
        value_2 = read_control(knob_id[i], GET_SET_VALUE_2)
        option = read_control(knob_id[i], GET_SET_OPTION)
        print("Knob", i, "mode", mode, "value", value, "value_2", value_2, "option", option)

    # set pads
    for i, pad in enumerate(pad_id):
        write_control(pad, GET_SET_MODE, MODE_SWITCHED)
        write_control(pad, GET_SET_VALUE_2, pad_cc[i])
        write_control(pad, GET_SET_OPTION, OPTION_GATE)
        write_control(pad, GET_SET_TOGGLE_COLOR, COLOR_RED)
    time.sleep(0.2)

    for i, pad in enumerate(pad_id):
        mode = read_control(pad, GET_SET_MODE)
        option = read_control(pad, GET_SET_OPTION)
        print("Pad", i, "mode", mode, "option", option)

    # suspicious values
    # control, param, current value
    # 27 64 2
    # 80 1 8
    # 80 2 65
    # 80 3 64
    # 80 5 127
    # 80 6 1

    print("End")
except KeyboardInterrupt:
    pass


