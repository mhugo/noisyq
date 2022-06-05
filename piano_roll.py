from dataclasses import dataclass

from PyQt5.QtCore import pyqtProperty, pyqtSlot, QSize, Qt, QVariant, QObject
from PyQt5.QtGui import QColor, QPen, QPainter, QBrush
from PyQt5.QtQuick import QQuickPaintedItem

from typing import List, Optional

from time_unit import TimeUnit
from qsequencer import QSequencer


class PianoRoll(QQuickPaintedItem):
    def __init__(self, parent=None):
        print("PianoRoll", parent)
        super().__init__(parent)
        # 1 step = 1 beat = 1 black note
        self._steps_per_screen = 4
        self._notes_per_screen = 12

        # time offset
        self._offset = TimeUnit(0)
        # note offset
        self._note_offset = 60

        # the sequencer from where to fetch notes to display
        self._sequencer: QSequencer

        self._channel = 0

        # step that is currently lit during a playback
        self._lit_step: Optional[int] = None

    @pyqtProperty(int)
    def stepsPerScreen(self) -> int:
        return self._steps_per_screen

    @stepsPerScreen.setter
    def stepsPerScreen(self, steps: int):
        self._steps_per_screen = steps
        self.update()

    @pyqtProperty(QObject)
    def sequencer(self) -> QSequencer:
        return self._sequencer

    @sequencer.setter
    def sequencer(self, seq):
        self._sequencer = seq
        self._sequencer.step.connect(self.on_step)

    def on_step(self, step):
        self._lit_step = step
        self.update()

    @pyqtProperty(int)
    def channel(self) -> int:
        return self._channel

    @channel.setter
    def channel(self, ch):
        self._channel = ch
        self.update()

    @pyqtProperty(int)
    def offset(self):
        return int(self._offset)

    @offset.setter
    def offset(self, off: int):
        self._offset = TimeUnit(off, 1)
        self.update()

    @pyqtProperty(int)
    def note_offset(self):
        return self._note_offset

    @note_offset.setter
    def note_offset(self, off: int):
        self._note_offset = off
        self.update()

    # TODO
    def notesPerScreen(self) -> int:
        pass

    def is_in_chord(self, note: int) -> bool:
        # FIXME only major chord for now
        return (note % 12) in (0, 2, 4, 5, 7, 9, 11)

    def paint(self, painter: QPainter) -> None:
        painter.save()
        # lines with background
        dark_brush = QBrush(QColor("#aaa"))
        light_brush = QBrush(QColor("#eee"))
        no_pen = QPen()
        no_pen.setStyle(Qt.NoPen)
        painter.setPen(no_pen)
        h = (self.height() - 1) / self._notes_per_screen
        for j in range(self._notes_per_screen + 1):
            y = int(j * h)
            if self.is_in_chord(j + self._note_offset):
                painter.setBrush(light_brush)
            else:
                painter.setBrush(dark_brush)
            painter.drawRect(0, y, int(self.width()), int(h))

        # lit step, if any
        if self._lit_step is not None:
            step = int(self._lit_step - self._offset)
            if step >= 0 and step < self._steps_per_screen:
                play_brush = QBrush(QColor("#80fafabb"))
                painter.setBrush(play_brush)
                painter.setPen(no_pen)
                w = (self.width() - 1) / self._steps_per_screen
                x = step * w
                painter.drawRect(x, 0, w, int(self.height() - 1))

        painter.restore()
        # FIXME: add black piano roll when the displayed part is past the end

        thick_pen = QPen()
        thick_pen.setWidth(2)
        normal_pen = QPen()
        # vertical lines
        for i in range(self._steps_per_screen + 1):
            x = int(i * (self.width() - 1) / self._steps_per_screen)
            if int(i - self._offset) % 4 == 0:
                painter.setPen(thick_pen)
            else:
                painter.setPen(normal_pen)
            painter.drawLine(x, 0, x, int(self.height()))

        # notes
        light = QBrush(QColor("#23629e"))
        dark = QBrush(QColor("#3492eb"))
        painter.setPen(no_pen)
        stop = self._offset + self._steps_per_screen
        for event in self._sequencer.list_events(
            self._offset.amount(), self._offset.unit(), stop.amount(), stop.unit()
        ):
            print("channel", self._channel)
            if event["channel"] != self._channel:
                continue
            print("event", event)
            note = event["event"]["note"]
            print("note - note_offset", note - self._note_offset)
            if note - self._note_offset < 0:
                continue
            if note - self._note_offset >= self._notes_per_screen:
                continue
            velocity = event["event"]["velocity"]
            note_time = TimeUnit(event["time_amount"], event["time_unit"])
            note_duration = TimeUnit(
                event["event"]["duration_amount"], event["event"]["duration_unit"]
            )
            x = (
                float(note_time - self._offset)
                / self._steps_per_screen
                * (self.width() - 1)
            )
            w = float(note_duration) / self._steps_per_screen * (self.width() - 1)
            y = (
                (note - self._note_offset)
                / self._notes_per_screen
                * (self.height() - 1)
            )
            h = (self.height() - 1) / self._notes_per_screen

            painter.setBrush(light)
            painter.drawRect(x, y, w, h)
            painter.setBrush(dark)
            b = 4
            painter.drawRect(x + b, y + b, w - b * 2, h - b * 2)
