# MIDI controlled menu

Prototype for a graphical menu to synthesizers' tuning parameters controlled
by MIDI messages.

The aim is to be able to plug a MIDI controller (like the Arturia Minilab) and
configure it to control parameters of a bunch of VST (Helm, samplv1, etc.), focusing
on live knob editing.

## How to run it

The prototype is made of a QML application written in Python with PyQt.

1. Initialize the virtual environment

```
virtualenv -p /usr/bin/python3 --system-site-packages venv
source venv/bin/activate
pip install -r requirements.txt
```

2. Launch the application

```
python midi_control.py
```

