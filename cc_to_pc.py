import rtmidi

import time

import argparse

api = rtmidi.API_LINUX_ALSA

parser = argparse.ArgumentParser(
    description="Replace one MIDI CC message from its input to a Program Change on its output."
)
parser.add_argument('--alsa', action="store_true",
                    help='Use ALSA MIDI')
parser.add_argument('--jack', action="store_true",
                    help="Use JACK MIDI")
parser.add_argument('--cc', action="store", type=int,
                    required=True,
                    help="Input MIDI CC number")
parser.add_argument('--debug', action="store_true",
                    help="Debug MIDI")

args = parser.parse_args()

print("Remap CC {} to Program Change".format(args.cc))
if args.debug:
    print("Debug mode ON")

if args.alsa:
    api = rtmidi.API_LINUX_ALSA
elif args.jack:
    api = rtmidi.API_UNIX_JACK

midi_in = rtmidi.MidiIn(api, name="MIDI CC to PC")
midi_in.open_virtual_port("MIDI CC to PC IN")
midi_in.ignore_types(sysex=False)

midi_out = rtmidi.MidiOut(api, name="MIDI CC to PC")
midi_out.open_virtual_port("MIDI CC to PC OUT")

def on_midi(event, data):
    in_msg, ts = event

    out_msg = in_msg

    if (in_msg[0] & 0xF0) == 0xB0:
        channel = in_msg[0] & 0xF
        cc = in_msg[1]
        value = in_msg[2]
        if cc == args.cc:
            # replace by program change
            out_msg = [0xC0 + channel, value]
            print("CC {} => PC {}".format(args.cc, value))

    midi_out.send_message(out_msg)

    if args.debug:
        print(
            " ".join(["%02X" % x for x in in_msg]),
            "=>",
            " ".join(["%02X" % x for x in out_msg])
        )

midi_in.set_callback(on_midi)

while True:
    time.sleep(10)


