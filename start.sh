###!/usr/bin/env bash
carla-jack-multi carla/test_multi_jack.carxp &
python midi_control.py &
