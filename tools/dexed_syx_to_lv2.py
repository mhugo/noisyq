import argparse
import rdflib
from rdflib import Namespace, RDF, RDFS, URIRef, Literal
import os
import sys

from pathlib import Path

# byte offset, bit mask, bit offset, max value for each parameter
op_parameter_list = [
    ("eg_rate_1", 0, 0x7F, 0, 99),
    ("eg_rate_2", 1, 0x7F, 0, 99),
    ("eg_rate_3", 2, 0x7F, 0, 99),
    ("eg_rate_4", 3, 0x7F, 0, 99),
    ("eg_level_1", 4, 0x7F, 0, 99),
    ("eg_level_2", 5, 0x7F, 0, 99),
    ("eg_level_3", 6, 0x7F, 0, 99),
    ("eg_level_4", 7, 0x7F, 0, 99),
    ("break_point", 8, 0x7F, 0, 99),
    ("l_scale_depth", 9, 0x7F, 0, 99),
    ("r_scale_depth", 10, 0x7F, 0, 99),
    ("l_key_scale", 11, 3, 0, 3),
    ("r_key_scale", 11, 3, 2, 3),
    ("rate_scaling", 12, 7, 0, 7),
    ("mod_sens_", 13, 3, 0, 3),
    ("key_velocity", 13, 7, 2, 7),
    ("output_level", 14, 0x7F, 0, 99),
    ("mode", 15, 1, 0, 1),
    ("f_coarse", 15, 31, 1, 31),
    ("f_fine", 16, 0x7F, 0, 99),
    ("osc_detune", 12, 15, 3, 14),
]


# The order of parameter names is the order inside a single voice dump
parameter_list = [
    (f"op{n}_" + p[0], p[1] + 17 * (6 - n), p[2], p[3], p[4])
    for n in range(6, 0, -1)
    for p in op_parameter_list
] + [
    ("pitch_eg_rate_1", 102, 0x7F, 0, 99),
    ("pitch_eg_rate_2", 103, 0x7F, 0, 99),
    ("pitch_eg_rate_3", 104, 0x7F, 0, 99),
    ("pitch_eg_rate_4", 105, 0x7F, 0, 99),
    ("pitch_eg_level_1", 106, 0x7F, 0, 99),
    ("pitch_eg_level_2", 107, 0x7F, 0, 99),
    ("pitch_eg_level_3", 108, 0x7F, 0, 99),
    ("pitch_eg_level_4", 109, 0x7F, 0, 99),
    ("algorithm", 110, 31, 0, 31),
    ("feedback", 111, 7, 0, 7),
    ("osc_key_sync", 111, 1, 3, 1),
    ("lfo_speed", 112, 0x7F, 0, 99),
    ("lfo_delay", 113, 0x7F, 0, 99),
    ("lfo_pm_depth", 114, 0x7F, 0, 99),
    ("lfo_am_depth", 115, 0x7F, 0, 99),
    ("lfo_key_sync", 116, 1, 0, 1),
    ("lfo_wave", 116, 15, 1, 5),
    ("p_mode_sens_", 116, 7, 4, 7),
    ("middle_c", 117, 0x7F, 0, 48),
]

lv2_header = """@prefix atom: <http://lv2plug.in/ns/ext/atom#> .
@prefix lv2: <http://lv2plug.in/ns/lv2core#> .
@prefix pset: <http://lv2plug.in/ns/ext/presets#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix state: <http://lv2plug.in/ns/ext/state#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<{bank}_{preset_label}.ttl>
	a pset:Preset ;
	lv2:appliesTo <https://github.com/asb2m10/dexed> ;
        rdfs:label "{preset_label}" ;

    lv2:port 
"""

lv2_parameter_value = """	[
		lv2:symbol "{name}" ;
		pset:value {value}
	]"""


def read_byte(fi) -> int:
    return int.from_bytes(fi.read(1), "little")


def read_sysex_ushort(fi) -> int:
    a = read_byte(fi)
    b = read_byte(fi)
    return b + (a << 7)


def read_until_sysex_end(fi):
    while fi.read(1) != b"\xF7":
        pass


dexed_uri = URIRef("https://github.com/asb2m10/dexed")
pset = Namespace("http://lv2plug.in/ns/ext/presets#")
lv2 = Namespace("http://lv2plug.in/ns/lv2core#")


class LV2PresetWriter:
    def __init__(self, output_dir: Path):
        self._output_dir = output_dir
        output_dir.mkdir(parents=True, exist_ok=True)
        self._g = rdflib.Graph()
        self._manifest_filename = output_dir / "manifest.ttl"
        if self._manifest_filename.exists():
            self._g.parse(self._manifest_filename)

            # parse() always reads URIRef as absolute file://
            # which makes the manifest file not "portable"
            # Remove the base uri from URIRefs in a new graph ...
            base_uri = output_dir.as_uri()
            ng = rdflib.Graph()
            for s, p, o in self._g:
                if isinstance(s, str) and s.startswith(base_uri):
                    s = URIRef(s[len(base_uri) + 1 :])
                if isinstance(o, str) and o.startswith(base_uri):
                    o = URIRef(o[len(base_uri) + 1 :])
                ng.add((s, p, o))
            self._g = ng

        else:
            self._g.bind("lv2", lv2)
            self._g.bind("pset", pset)

    def finalize(self):
        with open(self._manifest_filename, "w") as fo:
            fo.write(self._g.serialize(format="ttl", auto_compact=True))

    def write_lv2_preset(self, bank: str, name: str, params):
        lv2_name = " ".join(name.split()).replace(" ", "_")
        filename = self._output_dir / f"{bank}_{lv2_name}.ttl"

        # create bank
        bank_uri = URIRef(f"Dexed_bank_{bank}")
        if (bank_uri, RDF.type, pset.bank) not in self._g:
            self._g.add((bank_uri, RDF.type, pset.bank))
            self._g.add((bank_uri, RDFS.label, Literal(bank)))
            self._g.add((bank_uri, lv2.appliesTo, dexed_uri))

        # create preset
        preset_uri = URIRef(f"{bank}_{lv2_name}.ttl")
        if (preset_uri, RDF.type, pset.Preset) not in self._g:
            self._g.add((preset_uri, RDF.type, pset.Preset))
            self._g.add((preset_uri, pset.bank, bank_uri))
            self._g.add((preset_uri, RDFS.seeAlso, preset_uri))
            self._g.add((preset_uri, lv2.appliesTo, dexed_uri))

        print(f"Writing {filename} ...")
        with open(filename, "w") as fo:
            fo.write(lv2_header.format(bank=bank, preset_label=lv2_name))
            for i, (parameter_name, parameter_value) in enumerate(params.items()):
                fo.write(
                    lv2_parameter_value.format(
                        name=parameter_name, value=parameter_value
                    )
                )
                if i != len(params) - 1:
                    fo.write(",")
                else:
                    fo.write(".")


def print_preset(bank: str, name: str, params):
    print(bank, name)


def read_sysex_block(fi, preset_action):
    assert fi.read(1) == b"\xf0"
    assert fi.read(1) == b"\x43"  # YAMAHA
    sub_status = read_byte(fi)
    if sub_status != 0:
        print(f"Unknown SYSEX block with sub_status={sub_status}")
        return read_until_sysex_end(fi)

    format = read_byte(fi)
    if format == 0:  # 1 voice dump
        byte_count = read_sysex_ushort(fi)
        assert byte_count == 155
        params = {}
        block = fi.read(155)
        for i, (parameter_name, _, _, _, max_value) in enumerate(parameter_list):
            params[parameter_name] = block[i] / max_value
        name = block[145:].decode("ascii")

        check_sum = sum(b for b in block)
        check_sum = 127 - (check_sum & 0x7F) + 1
        expected_check_sum = read_byte(fi)
        assert check_sum == expected_check_sum
        eos = fi.read(1)
        assert eos == b"\xF7"

        for i in range(6):
            params[f"op{i+1}_switch"] = 1.0

        preset_action(name, params)

    elif format == 9:  # 32 voices dump
        byte_count = read_sysex_ushort(fi)
        assert byte_count == 4096
        check_sum = 0
        for voice in range(32):
            block = fi.read(128)
            for i in range(128):
                check_sum += block[i]
            name = block[118:].decode("ascii")
            params = {}
            for (
                parameter_name,
                byte_offset,
                bit_mask,
                bit_offset,
                max_value,
            ) in parameter_list:
                v = (block[byte_offset] & bit_mask) >> bit_offset
                assert v <= max_value
                params[parameter_name] = v / max_value
            for i in range(6):
                params[f"op{i+1}_switch"] = 1.0

            preset_action(name, params)
        check_sum = 127 - (check_sum & 0x7F) + 1
        expected_check_sum = read_byte(fi)
        assert check_sum == expected_check_sum
        eos = fi.read(1)
        assert eos == b"\xF7"
    else:
        print(f"Unknown SYSEX block with format={format}")
        read_until_sysex_end(fi)


parser = argparse.ArgumentParser(
    description="Convert DX7 .syx files to Dexed LV2 presets"
)
parser.add_argument("input_file", type=str, help="Input .syx file")
parser.add_argument(
    "--output-dir",
    help="Directory where to put LV2 presets",
    default=Path.home() / ".lv2",
)
parser.add_argument(
    "--bank",
    help="LV2 preset bank name",
    required=True,
)
parser.add_argument(
    "--list", help="Only lists preset names found in .syx file", action="store_true"
)

args = parser.parse_args()

if args.list:
    preset_action = lambda pname, params: print_preset(args.bank, pname, params)
else:
    writer = LV2PresetWriter(args.output_dir / f"Dexed_{args.bank}.presets.lv2")
    preset_action = lambda pname, params: writer.write_lv2_preset(
        args.bank, pname, params
    )

if True:
    with open(args.input_file, "rb") as fi:
        fi.seek(0, os.SEEK_END)
        file_len = fi.tell()
        fi.seek(0, os.SEEK_SET)
        while fi.tell() < file_len:
            read_sysex_block(fi, preset_action)

if not args.list:
    writer.finalize()
