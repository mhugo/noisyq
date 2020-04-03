# Python macro: generate a Python class
# FIXME: use macropy ??

keycodes = dict(
    [
        ("escape", 9),
        ("backspace", 12),
        ("page_up", 112),
        ("page_down", 117),
        ("right", 114),
        ("left", 113)
    ]
    # F keys
    + [
        ("f{}".format(n+1), n+67)
        for n in range(12)
    ]
    # Numbers
    + [
        ("number{}".format(n+1), n+10)
        for n in range(12)
    ]
    # azerty...
    + [
        ("row1_{}".format(n+1), n+24)
        for n in range(12)
    ]
    # qsdfgh...
    + [
        ("row2_{}".format(n+1), n+38)
        for n in range(12)
    ]
    # wxcv...
    + [
        ("row3_{}".format(n+1), n+52)
        for n in range(12)
    ]
)

print("""
from PyQt5.QtCore import QObject, pyqtProperty
class KeyCode(QObject):
    def __init__(self):
        super().__init__()""")
for keyname, keycode in keycodes.items():
    print("""
    @pyqtProperty(int)
    def k_{}(self):
        return {}""".format(
            keyname, keycode)
    )

