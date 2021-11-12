# Qt interface to sequencer
from enum import Enum
from fractions import Fraction
from typing import Any, Iterator, List, Literal, Optional, Set, Tuple

from PyQt5.QtCore import (
    pyqtSignal, pyqtSlot, pyqtProperty, QObject, QTimer, QElapsedTimer, QVariant,
)
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QPushButton
)
from PyQt5.QtQml import (
    QJSValue, QJSEngine
)
from sortedcontainers import SortedDict

TimeSubUnit = Literal[1, 2, 4, 8, 16, 32, 64, 128]


class TimeUnit:
    """
       A TimeUnit represents a fraction of a beat.
       It is stored as two integers. Denominator is a power of 2.
    """
    def __init__(self,
                 amount: int,
                 unit: TimeSubUnit = 1) -> None:
        self._fraction = Fraction(amount, unit)

    def amount(self):
        return self._fraction.numerator

    def unit(self):
        return self._fraction.denominator

    def __lt__(self, other):
        return self._fraction.__lt__(other._fraction)

    def __repr__(self):
        return repr(self._fraction)

    def __eq__(self, other):
        return self._fraction.__eq__(other._fraction)

    def __hash__(self):
        return self._fraction.__hash__()

    def __add__(self, other):
        r = TimeUnit(0)
        r._fraction = self._fraction + other._fraction
        return r


class ScheduledEvent:
    """
       A ScheduledEvent is a concrete event that can be
       sent to instruments. It is closed to MIDI events.
    """
    def __init__(self, time: TimeUnit):
        self.time = time


class NoteOnEvent(ScheduledEvent):
    def __init__(self, time: TimeUnit, note: int, velocity: int) -> None:
        super().__init__(time)
        self.note = note
        self.velocity = velocity

    def __repr__(self):
        return "@{} - NOTE ON({}, {})".format(self.time, self.note, self.velocity)


class NoteOffEvent(ScheduledEvent):
    def __init__(self, time: TimeUnit, note: int) -> None:
        super().__init__(time)
        self.note = note

    def __repr__(self):
        return "@{} - NOTE OFF({})".format(self.time, self.note)


class StopEvent(ScheduledEvent):
    def __init__(self, time: TimeUnit) -> None:
        super().__init__(time)

    def __repr__(self):
        return "@{} - STOP".format(self.time)


class Event:
    """
       An Event is a high-level event manipulated by the user
       in an editor and may be different from a ScheduledEvent.
       For example a NoteEvent will lead to two ScheduledEvents
       (a NoteOn followed by a NoteOff)
    """
    def schedule(self, start_time: TimeUnit) -> List[ScheduledEvent]:
        """
        Returns a list of ScheduledEvent
        """
        return []

    def to_dict(self):
        raise NotImplementedError

    @classmethod
    def from_dict(cls, d: dict) -> "Event":
        if d.get("event_type") == "note_event":
            return NoteEvent(d["note"], d["velocity"], TimeUnit(d["duration_amount"], d["duration_unit"]))
        return Event()


class NoteEvent(Event):
    def __init__(self, note: int, velocity: int, duration: TimeUnit):
        self.note = note
        self.velocity = velocity
        self.duration = duration

    def __repr__(self):
        return "(N={}, V={}, D={})".format(self.note, self.velocity, self.duration)

    def __eq__(self, other):
        return self.note == other.note and self.velocity == other.velocity and self.duration == other.duration

    def schedule(self, start_time: TimeUnit) -> List[ScheduledEvent]:
        return [
            NoteOnEvent(start_time, self.note, self.velocity),
            NoteOffEvent(start_time + self.duration, self.note)
        ]

    def to_dict(self):
        return {
            "event_type": "note_event",
            "note": self.note,
            "velocity": self.velocity,
            "duration_amount": self.duration.amount(),
            "duration_unit": self.duration.unit()
        }


class ParameterEvent(Event):
    # TODO
    pass


class ChannelEvent:
    """
       A simple channel + Event wrapper
    """
    def __init__(self, channel: int, event: Event) -> None:
        self.channel = channel
        self.event = event


def _add_event_to_sorted_dict(events: SortedDict, event: Any, start_time: TimeUnit) -> None:
    if start_time not in events:
        events[start_time] = [event]
    else:
        if event not in events[start_time]:
            events[start_time].append(event)


class State(Enum):
    STOPPED = 0
    PLAYING = 1
    PAUSED = 2


class ChronoMeter(QObject):
    """
       A chronometer can be started, paused, resumed and stopped.
       It displays (here through elapsed()) the cumulative elasped time.

       It can also trigger a signal after some given time, like a QTimer,
       but with the ability to pause it.
    """

    timeout = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__elapsed = 0
        self.__etimer = QElapsedTimer()
        self.__state = State.STOPPED

        self.__timer = QTimer(self)
        self.__timer.setSingleShot(True)
        # forward the internal timeout
        self.__timer.timeout.connect(self.__on_timeout)
        self.__interval = 0
        self.__single_shot = False

    @pyqtSlot(result=bool)
    def isSingleShot(self):
        return self.__single_shot

    @pyqtSlot(bool)
    def setSingleShot(self, s):
        self.__single_shot = s

    @pyqtSlot(result=int)
    def interval(self):
        return self.__interval

    @pyqtSlot(int)
    def setInterval(self, n_interval):
        self.__interval = n_interval

    def __on_timeout(self):
        """Called when the internal timer times out"""
        if self.__single_shot:
            self.__state = State.STOPPED
        else:
            # rearm
            self.__timer.setInterval(self.__interval)
            self.__timer.start()
        self.timeout.emit()

    @pyqtSlot()
    def start(self):
        if self.__state == State.STOPPED:
            #print("interval", self.__interval)
            self.__timer.setInterval(self.__interval)

        if self.__state != State.PLAYING:
            self.__etimer.start()
            self.__timer.start()
            self.__state = State.PLAYING

    @pyqtSlot()
    def stop(self):
        self.__elapsed = 0
        self.__etimer.invalidate()
        self.__timer.stop()
        self.__state = State.STOPPED

    @pyqtSlot()
    def pause(self):
        if self.__state == State.PLAYING:
            # pause
            self.__elapsed += self.__etimer.elapsed()
            self.__etimer.invalidate()
            # the timer is stopped before the timeout,
            self.__timer.setInterval(self.__timer.remainingTime())
            self.__timer.stop()

            self.__state = State.PAUSED

    @pyqtSlot()
    def elapsed(self) -> int:
        """
           Returns the accumulated elapsed time (in ms) since the last restart.
           The accumulated time does not include time spent during pauses.
        """
        if self.__etimer.isValid():
            return self.__elapsed + self.__etimer.elapsed()
        else:
            return self.__elapsed

    def is_playing(self):
        return self.__state == State.PLAYING


class QSequencer(QObject):

    noteOn = pyqtSignal(int, int, int, arguments=["channel", "note", "velocity"])
    noteOff = pyqtSignal(int, int, arguments=["channel", "note"])
    step = pyqtSignal(int, arguments=["step"])

    def __init__(self, parent=None):
        super().__init__(parent)
        # Events are stored in a dict sorted by time
        # key type: TimeUnit
        # value type: List[ChannelEvent]
        self.__events = SortedDict()

        self.__timer = QTimer()
        self.__timer.setSingleShot(True)
        self.__timer.timeout.connect(self.__on_timeout)

        # Main chrono for events
        self.__chrono = ChronoMeter()
        # Second chrono, with fixed interval for UI update
        self.__step_chrono = ChronoMeter()
        self.__step_chrono.setSingleShot(False)
        # At which interval the step signal is sent
        self.__step_unit = 4  # quarter note (noire)
        self.__step_number = 0
        self.__step_chrono.timeout.connect(self._on_step_timeout)

        # Time after pause and before the next note
        self.__remaining_time_after_pause = 0
        self.__scheduled_events = []
        self.__current_events = None
        self.__bpm = 120
        self.__state = State.STOPPED

        # Notes that are being played, so that stop can stop them all
        self.__sustained_notes: Set[Tuple[int, int]] = set()

    def _on_step_timeout(self):
        self.__step_number += 1
        self.step.emit(self.__step_number)

    def _add_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        _add_event_to_sorted_dict(self.__events,
                                  ChannelEvent(channel, event),
                                  start_time)

    @pyqtSlot(int, int, int, QVariant)
    def add_event(self, channel: int, start_time_amount,
                  start_time_unit: TimeSubUnit, event_dict: QJSValue) -> None:
        event = Event.from_dict(event_dict.toVariant())
        self._add_event(channel,
                        TimeUnit(start_time_amount, start_time_unit),
                        event)

    def _remove_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        if start_time in self.__events:
            for i, evt in enumerate(self.__events[start_time]):
                if evt.channel == channel and evt.event == event:
                    del self.__events[start_time][i]
                    if len(self.__events[start_time]) == 0:
                        del self.__events[start_time]
                    break

    @pyqtSlot(int, int, int, QVariant)
    def remove_event(self, channel: int, start_time_amount,
                     start_time_unit: TimeSubUnit, event_dict) -> None:
        print("event_dict", event_dict.toVariant())
        event = Event.from_dict(event_dict.toVariant())
        self._remove_event(channel,
                           TimeUnit(start_time_amount, start_time_unit),
                           event)

    def iterate_events(self,
                       start_time: Optional[TimeUnit] = None,
                       stop_time: Optional[TimeUnit] = None) -> Iterator[Tuple[int, TimeUnit, Event]]:
        # iterate events, by advancing time
        for event_time in self.__events.irange(start_time, stop_time, inclusive=[True, False]):
            for ch_event in self.__events[event_time]:
                yield ch_event.channel, event_time, ch_event.event

    def iterate_scheduled_events(self,
                                 start_time: Optional[TimeUnit] = None,
                                 stop_time: Optional[TimeUnit] = None,
                                 add_stop_event: bool = False) -> Iterator[
                                     Tuple[TimeUnit, ScheduledEvent]]:
        # First schedule events to obtain ScheduleEvents
        # key_type: TimeUnit
        # value_type: List[ScheduledEvent]
        scheduled_events = SortedDict()

        for channel, event_time, event in self.iterate_events(start_time, stop_time):
            events = event.schedule(event_time)
            for e in events:
                _add_event_to_sorted_dict(scheduled_events, (channel, e), e.time)

        # Then iterate over the list of scheduled events
        for event_time, e in scheduled_events.items():
            #print("Adding event @{} {}".format(event_time, e))
            yield event_time, e

        if stop_time and add_stop_event:
            #print("Adding stop event @{}".format(stop_time))
            yield stop_time, [(0, StopEvent(stop_time))]

    @pyqtSlot(int, int, int, int, result=list)
    @pyqtSlot(result=list)
    def list_events(self,
                    start_time: Optional[int] = None,
                    start_time_unit: Optional[TimeSubUnit] = None,
                    stop_time: Optional[int] = None,
                    stop_time_unit: Optional[TimeSubUnit] = None):
        start = TimeUnit(start_time, start_time_unit) \
            if start_time is not None and start_time_unit is not None \
            else None
        stop = TimeUnit(stop_time, stop_time_unit) \
            if stop_time is not None and stop_time_unit is not None \
            else None
        return [
            {
                "channel": channel,
                "time_amount": event_time.amount(),
                "time_unit": event_time.unit(),
                "event": event.to_dict()
            }
            for channel, event_time, event in self.iterate_events(start, stop)
        ]

    @pyqtSlot(int, int, int, result=QVariant)
    def get_event(self,
                  channel: int,
                  time_amount: int,
                  time_unit: TimeSubUnit):
        for e_channel, event_time, event in self.iterate_events(
                TimeUnit(time_amount, time_unit)):
            if channel == e_channel \
               and event_time == TimeUnit(time_amount, time_unit):
                return event.to_dict()

        return None

    @pyqtSlot(int, int, int, QVariant)
    def set_event(self, channel: int,
                  time_amount: int, time_unit: TimeSubUnit,
                  event):
        for evt in self.__events.get(TimeUnit(time_amount, time_unit), []):
            if evt.channel == channel:
                evt.event = Event.from_dict(event.toVariant())
                break

    stateChanged = pyqtSignal()

    def __state_change(self, new_state: State) -> None:
        self.__state = new_state
        self.stateChanged.emit()

    def __on_timeout(self):
        # We rearm the timeout. Make sure self.__current_events is copied
        # otherwise it could be overwritten while not processed yet
        events = list(self.__current_events)
        self.__arm_next_event()

        # The following tasks should not take more time than allocated !
        print("Timeout @", self.__chrono.elapsed(), events)
        for channel, event in events:
            if isinstance(event, NoteOnEvent):
                self.__sustained_notes.add((channel, event.note))
                self.noteOn.emit(channel, event.note, event.velocity)
            elif isinstance(event, NoteOffEvent):
                self.__sustained_notes.remove((channel, event.note))
                self.noteOff.emit(channel, event.note)
            elif isinstance(event, StopEvent):
                #print("!!!STOP!!!")
                self.stop()
            else:
                raise TypeError("Unknown event type!")

    def __arm_next_event(self):
        if self.__scheduled_events:
            if not self.__current_events:
                e_ms = 0
                self.__chrono.start()
            else:
                e_ms = self.__chrono.elapsed()
            event_time, self.__current_events = self.__scheduled_events.pop(0)
            next_ms = int(event_time.amount() * 60 * 1000 / event_time.unit() / self.__bpm)
            #print("start timer", next_ms - e_ms)
            self.__timer.start(next_ms - e_ms)
        else:
            #print("***STOP")
            self.__state_change(State.STOPPED)
            self.__chrono.stop()
            self.__step_chrono.stop()

    def play(self, bpm: int,
             start_time_amount: int, start_time_unit: TimeSubUnit,
             stop_time_amount: int, stop_time_unit: TimeSubUnit):
        #print("***PLAY")
        assert self.__state == State.STOPPED
        self.__bpm = bpm
        self.__step_chrono.setInterval(int(60.0 / bpm * 1000 / self.__step_unit))

        # Play
        self.__scheduled_events = list(self.iterate_scheduled_events(
            TimeUnit(start_time_amount, start_time_unit),
            TimeUnit(stop_time_amount, stop_time_unit),
            add_stop_event=True
        ))
        print("\n".join([repr(e) for e in self.__scheduled_events]))
        
        self.__current_events = None
        self.__arm_next_event()

        self.__chrono.start()
        self.__step_chrono.start()
        self.__state_change(State.PLAYING)
        self.step.emit(self.__step_number)

    def pause(self):
        #print("***PAUSE")
        assert self.__state == State.PLAYING
        self.__remaining_time_after_pause = self.__timer.remainingTime()
        self.__timer.stop()
        self.__chrono.pause()
        self.__step_chrono.pause()
        self.__state_change(State.PAUSED)

    def resume(self):
        #print("***RESUME")
        assert self.__state == State.PAUSED

        # Resume from pause
        self.__timer.start(self.__remaining_time_after_pause)
        self.__chrono.start()
        self.__step_chrono.start()
        self.__state_change(State.PLAYING)
        self.step.emit(self.__step_number)

    @pyqtSlot()
    def stop(self):
        #print("***STOP")
        self.__timer.stop()
        self.__remaining_time_after_pause = 0
        self.__chrono.stop()
        self.__step_chrono.stop()
        self.__step_number = 0
        self.__state_change(State.STOPPED)
        # Send note off to notes currently playing !
        while len(self.__sustained_notes):
            channel, note = self.__sustained_notes.pop()
            self.noteOff.emit(channel, note)

    @pyqtSlot(int, int, int, int, int)
    def toggle_play_pause(self, bpm,
                          start_time_amount, start_time_unit,
                          stop_time_amount, stop_time_unit):
        if self.__state == State.STOPPED:
            self.play(bpm, start_time_amount, start_time_unit,
                      stop_time_amount, stop_time_unit)
        elif self.__state == State.PLAYING:
            self.pause()
        elif self.__state == State.PAUSED:
            self.resume()

    @pyqtSlot(result=bool)
    def is_playing(self):
        return self.__state == State.PLAYING

    @pyqtProperty(int)
    def bpm(self):
        return self.__bpm


if __name__ == "__main__":
    app = QApplication([])

    def dict_to_js_object(engine: QJSEngine, d: dict) -> QJSValue:
        obj = engine.newObject()
        for key, value in d.items():
            obj.setProperty(key, value)
        return obj

    engine = QJSEngine()

    seq = QSequencer()
    seq.add_event(0, 0, 1, dict_to_js_object(
        engine, {
            "event_type": "note_event",
            "note": 60,
            "velocity": 120,
            "duration_amount": 1,
            "duration_unit": 1,
        }))

    print(seq.list_events())
    #app.exec_()
