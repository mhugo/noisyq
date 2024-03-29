from dataclasses import dataclass

from PyQt5.QtCore import pyqtProperty, pyqtSlot, QSize, Qt, QVariant, QObject
from PyQt5.QtGui import QColor, QPen, QPainter, QBrush, QFont
from PyQt5.QtQuick import QQuickPaintedItem

from typing import Dict, Optional, Set

from qsequencer import QSequencer

TimeUnit = int
TIME_UNIT = 256


def midi_note_name(note: int) -> str:
    name_en = ["C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#", "A ", "A#", "B "]
    # name_fr = ["Do", "Do#", "Ré", "Ré#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"]
    return "{}{}".format(name_en[note % 12], ((note + 3) // 12) - 1)


class NoteSelection:
    def __init__(self):
        # selected notes: channel -> TimeUnit -> [note]
        self._selection: Dict[int, Dict[TimeUnit, Set[int]]] = {}

    def toggle_selection(self, channel: int, time: TimeUnit, note: int):
        notes = self._selection.setdefault(channel, {}).setdefault(time, set())
        if note in notes:
            notes.remove(note)
        else:
            notes.add(note)

    def is_selected(self, channel: int, time: TimeUnit, note: int) -> bool:
        return note in self._selection.get(channel, {}).get(time, {})


class PianoRoll(QQuickPaintedItem):
    def __init__(self, parent=None):
        super().__init__(parent)
        # max horizontal stacking of steps per screen
        self._bars_per_screen = 2
        # max vertical stacking of notes
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

        # cursor
        self._cursor_x = TimeUnit(0)
        self._cursor_y = 0
        self._cursor_width = TimeUnit(1)

        self._selected_notes = NoteSelection()

        # notes playing when a key is pressed
        self._notes_playing = set()

    """
    @pyqtProperty(int)
    def stepsPerScreen(self) -> int:
        return self._steps_per_screen

    @stepsPerScreen.setter
    def stepsPerScreen(self, steps: int):
        self._steps_per_screen = steps
        self.update()
    """

    @pyqtProperty(int)
    def barsPerScreen(self) -> int:
        return self._bars_per_screen

    @barsPerScreen.setter
    def barsPerScreen(self, bars: int):
        self._bars_per_screen = bars
        self.update()

    def steps_per_screen(self) -> int:
        return self._bars_per_screen * self._sequencer.time_signature()[0]

    @pyqtProperty(QObject)
    def sequencer(self) -> QSequencer:
        return self._sequencer

    @sequencer.setter
    def sequencer(self, seq):
        self._sequencer = seq
        self._sequencer.step.connect(self.on_step)
        self._sequencer.time_signature_set.connect(self.update)

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
        self._offset = TimeUnit(off)
        self.update()

    @pyqtProperty(int)
    def note_offset(self):
        return self._note_offset

    @note_offset.setter
    def note_offset(self, off: int):
        self._note_offset = off
        self.update()

    @pyqtProperty(int)
    def cursor_x(self):
        return self._cursor_x

    @pyqtProperty(int)
    def cursor_x(self):
        return self._cursor_x

    @cursor_x.setter
    def cursor_x(self, x: int):
        self._cursor_x = x
        self.update()

    @pyqtProperty(int)
    def cursor_y(self):
        return self._cursor_y

    @cursor_y.setter
    def cursor_y(self, y: int):
        self._cursor_y = y
        self.update()

    @pyqtSlot()
    def increment_cursor_x(self):
        """
        Increment self._cursor_x by self._cursor_width
        except if we are on the right part of the screen where incrementing x makes self._offset increments (by cursor width)
        """
        time_signature = self._sequencer.time_signature()
        cursor_time = self._offset + self._cursor_x
        total_time = (
            self._sequencer.n_bars * time_signature[0] * TIME_UNIT / time_signature[1]
        )
        if self._sequencer.n_bars <= self._bars_per_screen:
            if self._cursor_x < total_time - self._cursor_width:
                self._cursor_x += self._cursor_width
        else:
            max_time = (
                self._bars_per_screen
                * time_signature[0]
                * TIME_UNIT
                / time_signature[1]
            )
            if self._cursor_x == max_time - self._cursor_width:
                if self._offset + self._cursor_x < total_time - self._cursor_width:
                    self._offset += self._cursor_width
            elif self._cursor_x < max_time - self._cursor_width:
                self._cursor_x += self._cursor_width
        self.update()

    @pyqtSlot()
    def decrement_cursor_x(self):
        if self._cursor_x == 0:
            if self._offset > 0:
                self._offset -= self._cursor_width
        else:
            self._cursor_x -= self._cursor_width
        self.update()

    @pyqtSlot()
    def increment_cursor_y(self):
        if self._cursor_y == self._notes_per_screen - 1:
            # TODO test max offset
            self._note_offset += 1
        else:
            self._cursor_y += 1
        self.update()

    @pyqtSlot()
    def decrement_cursor_y(self):
        if self._cursor_y == 0:
            if self._note_offset > 0:
                self._note_offset -= 1
        else:
            self._cursor_y -= 1
        self.update()

    @pyqtProperty(int)
    def cursor_width(self):
        return self._cursor_width

    @pyqtSlot(int)
    def set_cursor_width(self, amount):
        self._cursor_width = TimeUnit(amount)
        self.update()

    @cursor_y.setter
    def cursor_y(self, y: int):
        self._cursor_y = y
        self.update()

    @pyqtSlot(result=int)
    def cursor_start(self) -> int:
        return self._offset + self._cursor_x

    @pyqtSlot(result=int)
    def cursor_end(self) -> int:
        return self.cursor_start() + self._cursor_width

    # TODO
    def notesPerScreen(self) -> int:
        pass

    @pyqtSlot(int, int, int)
    def toggleNoteSelection(self, voice: int, time_amount: int, note: int):
        self._selected_notes.toggle_selection(voice, TimeUnit(time_amount), note)

    @pyqtSlot(int)
    def noteOn(self, note: int):
        self._notes_playing.add(note)
        self.update()

    @pyqtSlot(int)
    def noteOff(self, note: int):
        self._notes_playing.remove(note)
        self.update()

    def is_in_chord(self, note: int) -> bool:
        # FIXME only major chord for now
        return (note % 12) in (0, 2, 4, 5, 7, 9, 11)

    def paint(self, painter: QPainter) -> None:
        painter.save()

        # lines with background
        dark_brush = QBrush(QColor("#aaa"))
        playing_brush = QBrush(QColor("#ccc"))
        light_brush = QBrush(QColor("#eee"))
        no_pen = QPen()
        no_pen.setStyle(Qt.NoPen)
        no_brush = QBrush()
        no_brush.setStyle(Qt.NoBrush)

        note_labels_width = 30
        notes_width = self.width() - note_labels_width
        notes_x = note_labels_width

        steps_per_screen = self.steps_per_screen()
        time_signature = self._sequencer.time_signature()

        # max displayed steps = either the number of steps per screen
        # or a bit less, if we've reached the total number of steps
        n_displayed_steps = min(
            self._sequencer.n_bars * time_signature[0]
            - int(self._offset / TIME_UNIT * time_signature[1]),
            steps_per_screen,
        )
        max_width = int(n_displayed_steps * notes_width / steps_per_screen)

        painter.setPen(no_pen)
        h = (self.height() - 1) / self._notes_per_screen
        for j in range(self._notes_per_screen + 1):
            y = int((self._notes_per_screen - j - 1) * h)
            note = j + self._note_offset
            if note in self._notes_playing:
                painter.setBrush(playing_brush)
            elif self.is_in_chord(j + self._note_offset):
                painter.setBrush(light_brush)
            else:
                painter.setBrush(dark_brush)
            # draw horizontal lines
            painter.drawRect(notes_x, y, max_width, int(h))
            # draw note labels
            painter.drawRect(0, y, note_labels_width, int(h))

        black_pen = QPen()
        painter.setPen(black_pen)
        font = QFont("courier")
        font.setPixelSize(h - 2)
        font.setWeight(QFont.Bold)
        painter.setFont(font)
        for j in range(self._notes_per_screen + 1):
            y = int((self._notes_per_screen - j - 1) * h)
            note = j + self._note_offset
            # draw note labels
            painter.drawText(0, y + h - 2, midi_note_name(note))

        a = time_signature[1] / 4

        # lit step, if any
        if self._lit_step is not None:
            step = int(self._lit_step - self._offset / TIME_UNIT)
            if step >= 0 and step < steps_per_screen:
                play_brush = QBrush(QColor("#80fafabb"))
                painter.setBrush(play_brush)
                painter.setPen(no_pen)
                w = notes_width / steps_per_screen * a
                x = step * w + notes_x
                painter.drawRect(x, 0, w, int(self.height() - 1))

        # draw cursor
        duration_per_screen = steps_per_screen / time_signature[1]
        x = self._cursor_x * notes_width / TIME_UNIT / duration_per_screen + notes_x
        w = self._cursor_width * notes_width / TIME_UNIT / self._bars_per_screen * a

        if self._cursor_x >= 0 and self._cursor_x < steps_per_screen * TIME_UNIT * a:
            cursor_brush = QBrush(QColor("#808cfaa4"))
            painter.setBrush(cursor_brush)
            painter.setPen(no_pen)
            painter.drawRect(x, 0, w, int(self.height() - 1))
        if self._cursor_y >= 0 and self._cursor_y < self._notes_per_screen:
            cursor_pen = QPen(QColor("black"))
            cursor_pen.setWidth(2)
            painter.setBrush(no_brush)
            painter.setPen(cursor_pen)
            h = (self.height() - 1) / self._notes_per_screen
            y = (self._notes_per_screen - self._cursor_y - 1) * h
            painter.drawRect(x, y, w, h)

        painter.restore()
        # FIXME: add black piano roll when the displayed part is past the end

        thick_pen = QPen()
        thick_pen.setWidth(2)
        normal_pen = QPen()
        # vertical lines
        for i in range(n_displayed_steps + 1):
            x = int(i * notes_width / steps_per_screen) + notes_x
            if (
                int(i + self._offset / TIME_UNIT * time_signature[1])
                % time_signature[0]
                == 0
            ):
                painter.setPen(thick_pen)
            else:
                painter.setPen(normal_pen)
            painter.drawLine(x, 0, x, int(self.height()))

        # notes
        light = QBrush(QColor("#23629e"))  # HSV 209°, 78%, 62%
        light_selected = QBrush(QColor("#9e9623"))  # HSV 56°, 78%, 62%
        dark_selected = QBrush(QColor("#ebde34"))  # HSV 56°, 78%, 92%
        painter.setPen(no_pen)
        stop = self._offset + steps_per_screen * TIME_UNIT
        for event in self._sequencer.list_events(self._offset, stop):
            if event["channel"] != self._channel:
                continue
            note = event["event"]["note"]
            if note - self._note_offset < 0:
                continue
            if note - self._note_offset >= self._notes_per_screen:
                continue
            velocity = event["event"]["velocity"]
            note_time = TimeUnit(event["time"])
            note_duration = TimeUnit(event["event"]["duration"])
            x = (
                (note_time - self._offset) / TIME_UNIT
            ) / duration_per_screen * notes_width + notes_x
            w = float(note_duration / TIME_UNIT) / duration_per_screen * notes_width
            y = (
                (self._notes_per_screen - (note - self._note_offset) - 1)
                / self._notes_per_screen
                * (self.height() - 1)
            )
            h = (self.height() - 1) / self._notes_per_screen

            note_selected = self._selected_notes.is_selected(
                self._channel, note_time, note
            )
            if note_selected:
                painter.setBrush(light_selected)
            else:
                painter.setBrush(light)
            painter.drawRect(x, y, w, h)
            if note_selected:
                painter.setBrush(dark_selected)
            else:
                # dark_color = QColor("#3492eb")  # HSV 209°, 78%, 92%
                # vary saturation w.r.t. velocity
                c = QColor.fromHsv(
                    209, int(velocity / 127.0 * 255.0), int(92 / 100.0 * 255.0)
                )
                painter.setBrush(QBrush(c))
            b = 4
            painter.drawRect(x + b, y + b, w - b * 2, h - b * 2)
