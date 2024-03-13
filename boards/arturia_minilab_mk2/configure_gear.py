"""
Configure Arturia Minilab mk2
Set knobs to infinite knobs with a free CC
Set pads to free CCs
"""

import time

prefix = [0xF0, 0x00, 0x20, 0x6B, 0x7F, 0x42]  # Arturia  # ??

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
KNOB_MODULATION = 0x40

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
    KNOB_16,
    KNOB_MODULATION,
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
    KNOB_9_BUTTON,
]

BTN_OCTAVE_DOWN = 0x10
BTN_OCTAVE_UP = 0x12
BTN_SHIFT = 0x2E
BTN_SWITCH_PADS = 0x2F
GLOBAL_CONTROL = 0x40
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
OPTION_TOGGLE = 0  # toggle button
OPTION_GATE = 1  # normal button

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

OP_KNOB_ACCELERATION = 0x1B
KNOB_ACCELERATION_SLOW = 0
KNOB_ACCELERATION_MEDIUM = 1
KNOB_ACCELERATION_FAST = 2

COLOR_BLACK = 0x00
COLOR_RED = 0x01
COLOR_BLUE = 0x10
COLOR_GREEN = 0x04
COLOR_PURPLE = 0x11
COLOR_CYAN = 0x14
COLOR_YELLOW = 0x05
COLOR_WHITE = 0x7F


def read_control(midi, control, operation):
    midi.send_message(
        prefix
        + [
            0x01,  # read value
            0x00,
            operation,  # operation
            control,  # knob 1
            0xF7,  # sysex end
        ]
    )
    msg, _ = midi.receive_message()
    return msg[10]


def _write_control(midi, control, operation, value):
    midi.send_message(
        prefix + [0x02, 0x00, operation, control, value, 0xF7]  # write value
    )


def write_control(midi, control, operation, value):
    for i in range(50):
        _write_control(midi, control, operation, value)
        time.sleep(0.0)
        actual_value = read_control(midi, control, operation)
        if actual_value == value:
            return
    assert False


def configure_gear(midi):
    # CC numbers for knobs
    knob_cc = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 1]
    # CC numbers for pads
    pad_cc = [
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,  # knob 1 switch
        72,  # knob 9 switch
    ]

    try:
        # ask sysexid
        midi.send_message([0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7])
        msg, ts = midi.receive_message()

        # set knobs
        for i, knob in enumerate(knob_id):
            write_control(midi, knob, GET_SET_MODE, MODE_CONTROL)
            # set CC
            write_control(midi, knob, GET_SET_VALUE_2, knob_cc[i])
            # set relative
            write_control(midi, knob, GET_SET_OPTION, OPTION_RELATIVE_1)

        for i, knob in enumerate(knob_id):
            mode = read_control(midi, knob, GET_SET_MODE)
            value = read_control(midi, knob, GET_SET_VALUE)
            value_2 = read_control(midi, knob, GET_SET_VALUE_2)
            option = read_control(midi, knob, GET_SET_OPTION)
            print(
                "Knob",
                i,
                "mode",
                mode,
                "value",
                value,
                "value_2",
                value_2,
                "option",
                option,
            )

        # set pads
        for i, pad in enumerate(pad_id):
            write_control(midi, pad, GET_SET_MODE, MODE_SWITCHED)
            write_control(midi, pad, GET_SET_VALUE_2, pad_cc[i])
            write_control(midi, pad, GET_SET_OPTION, OPTION_GATE)
            if pad not in (KNOB_1_BUTTON, KNOB_9_BUTTON):
                write_control(midi, pad, GET_SET_TOGGLE_COLOR, COLOR_RED)

        for i, pad in enumerate(pad_id):
            mode = read_control(midi, pad, GET_SET_MODE)
            option = read_control(midi, pad, GET_SET_OPTION)
            value = read_control(midi, pad, GET_SET_VALUE)
            value2 = read_control(midi, pad, GET_SET_VALUE_2)
            print(
                "Pad",
                i,
                "mode",
                mode,
                "option",
                option,
                "value",
                value,
                "value2",
                value2,
            )

        # suspicious values
        # control, param, current value
        # 27 64 2
        # 80 1 8
        # 80 2 65
        # 80 3 64
        # 80 5 127
        # 80 6 1

        # Knob acceleration
        write_control(
            midi, OP_KNOB_ACCELERATION, GLOBAL_CONTROL, KNOB_ACCELERATION_SLOW
        )
        r = read_control(midi, OP_KNOB_ACCELERATION, GLOBAL_CONTROL)
        print("Knob acceleration", r)

        print("End")
    except KeyboardInterrupt:
        pass


USB_DEVICE_NAME = "Arturia Minilab mkII"
