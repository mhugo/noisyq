from dataclasses import dataclass

from PyQt5.QtCore import pyqtProperty, pyqtSlot, QSize, Qt, QVariant, QObject
from PyQt5.QtGui import QColor, QPen, QPainter, QBrush
from PyQt5.QtQuick import QQuickPaintedItem

from typing import List

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

        # the sequencer from where to fetch notes to display
        self._sequencer: QSequencer

        self._channel = 0

    @pyqtProperty(int)
    def stepsPerScreen(self) -> int:
        return self._steps_per_screen

    @stepsPerScreen.setter
    def stepsPerScreen(self, steps: int):
        self._steps_per_screen = steps

    @pyqtProperty(QObject)
    def sequencer(self) -> QSequencer:
        return self._sequencer

    @sequencer.setter
    def sequencer(self, seq):
        self._sequencer = seq

    @pyqtProperty(int)
    def channel(self) -> int:
        return self._channel

    @channel.setter
    def channel(self, ch):
        self._channel = ch
        self.update()

    # TODO
    def notesPerScreen(self) -> int:
        pass

    def paint(self, painter: QPainter) -> None:
        # print("=================paint")
        # pen = QPen(QColor("black"))
        # pen.setWidth(2)
        # painter.setPen(pen)

        # vertical lines
        for i in range(self._steps_per_screen + 1):
            x = int(i * (self.width() - 1) / self._steps_per_screen)
            painter.drawLine(x, 0, x, int(self.height()))

        # horizontal lines
        for i in range(self._notes_per_screen + 1):
            y = int(i * (self.height() - 1) / self._notes_per_screen)
            painter.drawLine(0, y, int(self.width()), y)

        # notes
        stop = self._offset + self._steps_per_screen
        for event in self._sequencer.list_events(
            self._offset.amount(), self._offset.unit(), stop.amount(), stop.unit()
        ):
            print("channel", self._channel)
            if event["channel"] != self._channel:
                continue
            print("event", event)
            note = event["event"]["note"]
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
                (note % self._notes_per_screen)
                / self._notes_per_screen
                * (self.height() - 1)
            )
            h = (self.height() - 1) / self._notes_per_screen

            brush = QBrush(QColor("blue"))
            painter.setBrush(brush)
            painter.drawRect(x, y, w, h)
