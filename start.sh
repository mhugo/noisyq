###!/usr/bin/env bash
CARLA_OSC_UDP_PORT=12345 carla-jack-multi carla/test_multi_jack.carxp &
python midi_control.py &
