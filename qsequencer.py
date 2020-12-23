# Qt interface to sequencer
from fractions import Fraction
from typing import Any, Iterator, List, Literal, Optional, Tuple

from PyQt5.QtCore import (
    pyqtSignal, pyqtSlot, QObject, QTimer, QElapsedTimer
)
from sortedcontainers import SortedDict


class TimeUnit:
    """
       A TimeUnit represents a fraction of a beat.
       It is stored as two integers. Denominator is a power of 2.
    """
    def __init__(self, amount: int, unit: Literal[1, 2, 4, 8, 16, 32, 64, 128] = 1) -> None:
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


class QSequencer(QObject):

    def __init__(self, parent=None):
        super().__init__(parent)
        # Events are stored in a dict sorted by time
        # key type: TimeUnit
        # value type: List[ChannelEvent]
        self.__events = SortedDict()

        self.__timer = QTimer()
        self.__timer.setSingleShot(True)
        self.__timer.timeout.connect(self.__on_timeout)
        self.__elapsed_timer = QElapsedTimer()
        self.__scheduled_events = []
        self.__current_events = None
        self.__bpm = 120

        # FIXME
        self.add_event(1, TimeUnit(1, 2), NoteEvent(58, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(1), NoteEvent(61, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(2), NoteEvent(62, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(3), NoteEvent(65, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(4), NoteEvent(60, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(5), NoteEvent(63, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(6), NoteEvent(62, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(7), NoteEvent(61, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(8), NoteEvent(62, 64, TimeUnit(1)))

    noteOn = pyqtSignal(int, int, int, arguments=["channel", "note", "velocity"])
    noteOff = pyqtSignal(int, int, arguments=["channel", "note"])

    def add_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        _add_event_to_sorted_dict(self.__events,
                                  ChannelEvent(channel, event),
                                  start_time)

    def remove_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        if start_time in self.__events:
            for i, evt in enumerate(self.__events[start_time]):
                if evt.channel == channel and evt.event == event:
                    del self.__events[start_time][i]
                    if len(self.__events[start_time]) == 0:
                        del self.__events[start_time]
                    break

    def iterate_events(self,
                       start_time: Optional[TimeUnit] = None,
                       stop_time: Optional[TimeUnit] = None) -> Iterator[Tuple[int, TimeUnit, Event]]:
        # iterate events, by advancing time
        for event_time in self.__events.irange(start_time, stop_time):
            for ch_event in self.__events[event_time]:
                yield ch_event.channel, event_time, ch_event.event

    def iterate_scheduled_events(self,
                                 start_time: Optional[TimeUnit] = None,
                                 stop_time: Optional[TimeUnit] = None) -> Iterator[
                                     Tuple[int, TimeUnit, List[ScheduledEvent]]]:
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
            yield event_time, e

    @pyqtSlot(int, int, int, int, result=list)
    def list_events(self,
                    start_time: int, start_time_unit: int,
                    stop_time: int, stop_time_unit: int):
        return [
            {
                "channel": channel,
                "time_amount": event_time.amount(),
                "time_unit": event_time.unit(),
                "event": event.to_dict()
            }
            for channel, event_time, event in self.iterate_events(
                    TimeUnit(start_time, start_time_unit),
                    TimeUnit(stop_time, stop_time_unit)
            )
        ]

    def __on_timeout(self):
        # We rearm the timeout. Make sure self.__current_events is copied
        # otherwise it could be overwritten while not processed yet
        events = list(self.__current_events)
        self.__arm_next_event()

        # The following tasks should not take more time than allocated !
        print("Timeout @", self.__elapsed_timer.elapsed(), events)
        for channel, event in events:
            if isinstance(event, NoteOnEvent):
                self.noteOn.emit(channel, event.note, event.velocity)
            elif isinstance(event, NoteOffEvent):
                self.noteOff.emit(channel, event.note)
            else:
                raise TypeError("Unknown event type!")

    def __arm_next_event(self):
        if self.__scheduled_events:
            if not self.__current_events:
                e_ms = 0
                self.__elapsed_timer.start()
            else:
                e_ms = self.__elapsed_timer.elapsed()
            e = self.__scheduled_events.pop(0)
            event_time, self.__current_events = e
            next_ms = int(event_time.amount() * 60 * 1000 / event_time.unit() / self.__bpm)
            self.__timer.start(next_ms - e_ms)

    @pyqtSlot(int)
    def play(self, bpm):
        # TODO: add start_time, stop_time
        self.__bpm = bpm
        self.__scheduled_events = list(self.iterate_scheduled_events())
        # print("\n".join([repr(e) for e in self.__scheduled_events]))
        self.__current_events = None
        self.__arm_next_event()
