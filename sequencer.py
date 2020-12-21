from typing_extensions import Literal
from typing import Any, List, Tuple, Callable, Iterator, Optional

from collections import namedtuple
from fractions import Fraction
import sched
# pip install sortedcontainers
from sortedcontainers import SortedDict
import time

# Time unit = 1/128 of a beat
units_per_beat = 128


class TimeUnit(object):
    # FIXME: remove units and units_per_beat to simplify
    # FIXME: TimeUnit = number of beats
    def __init__(self, amount: int, unit: Literal[1, 2, 4, 8, 16, 32, 64, 128] = 1) -> None:
        self.units = amount * units_per_beat // unit
        self._fraction = Fraction(amount, unit)

    def amount(self):
        return self._fraction.numerator

    def unit(self):
        return self._fraction.denominator

    def __lt__(self, other):
        return self.units.__lt__(other.units)

    def __repr__(self):
        return repr(self.units)

    def __eq__(self, other):
        return self.units.__eq__(other.units)

    def __hash__(self):
        return self.units.__hash__()

    def __add__(self, other):
        r = TimeUnit(0)
        r.units = self.units + other.units
        r._fraction = self._fraction + other._fraction
        return r
            

class ScheduledEvent:
    def __init__(self, time: TimeUnit):
        self.time = time

class Event(object):
    def schedule(self, start_time : TimeUnit) -> List[ScheduledEvent]:
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
        return "(N={}, V={}, D={})".format(self.note, self.velocity, self.duration.units)

    def __eq__(self, other):
        return self.note == other.note and self.velocity == other.velocity and self.duration == other.duration

    def schedule(self, start_time : TimeUnit) -> List[ScheduledEvent]:
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


class ChannelEvent:
    def __init__(self, channel: int, event: Event) -> None:
        self.channel = channel
        self.event = event


def _add_event_to_sorted_dict(events: SortedDict, event: Any, start_time: TimeUnit) -> None:
    if start_time not in events:
        events[start_time] = [event]
    else:
        if event not in events[start_time]:
            events[start_time].append(event)
    
        
class Sequencer(object):

    N_CHANNELS = 16

    beats_per_minute = 120

    CallbackType = Callable[[int, ScheduledEvent], None]

    def __init__(self):
        # key_type: TimeUnit
        # value_type: List[ChannelEvent]
        self.__events = SortedDict()

        self.__sched: sched.scheduler

        # default callback
        self.__callback = print_sch_event

        self.add_event(1, TimeUnit(1, 2), NoteEvent(58, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(1), NoteEvent(61, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(2), NoteEvent(62, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(3), NoteEvent(65, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(4), NoteEvent(60, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(5), NoteEvent(63, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(6), NoteEvent(62, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(7), NoteEvent(61, 64, TimeUnit(1)))
        self.add_event(0, TimeUnit(8), NoteEvent(62, 64, TimeUnit(1)))

    def add_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        _add_event_to_sorted_dict(self.__events,
                                  ChannelEvent(channel, event),
                                  start_time)

    def iterate_scheduled_events(self, start_time: Optional[TimeUnit] = None, stop_time: Optional[TimeUnit] = None) -> Iterator[Tuple[int, TimeUnit, List[ScheduledEvent]]]:
        # key_type: TimeUnit
        # value_type: List[ScheduledEvent]
        scheduled_events = SortedDict()

        for channel, event_time, event in self.iterate_events(start_time, stop_time):
            events = event.schedule(event_time)
            for e in events:
                _add_event_to_sorted_dict(scheduled_events, (channel, e), e.time)

        for event_time, e in scheduled_events.items():
            yield event_time, e

    def remove_event(self, channel: int, start_time: TimeUnit, event: Event) -> None:
        if start_time in self.__events:
            for i, evt in enumerate(self.__events[start_time]):
                if evt.channel == channel and evt.event == event:
                    del self.__events[start_time][i]
                    if len(self.__events[start_time]) == 0:
                        del self.__events[start_time]
                    break

    def iterate_events(self, start_time: Optional[TimeUnit] = None, stop_time : Optional[TimeUnit] = None) -> Iterator[Tuple[int, TimeUnit, Event]]:
        # iterate events, by advancing time
        for event_time in self.__events.irange(start_time, stop_time):
            for ch_event in self.__events[event_time]:
                yield ch_event.channel, event_time, ch_event.event

    def set_callback(self, callback: CallbackType) -> None:
        self.__callback = callback

    def __schedule(self):

        def _units_to_seconds(units):
            return (units / units_per_beat) / self.beats_per_minute * 60

        # reset the scheduler
        self.__sched = sched.scheduler(
            time.time,
            lambda units: time.sleep(_units_to_seconds(units))
        )

        if self.__callback:
            for channel, start_time, abstract_event in self.iterate_events():
                events = abstract_event.schedule(start_time)
                for event in events:
                    self.__sched.enter(
                        _units_to_seconds(event.time.units),
                        1,  # priority
                        self.__callback,
                        [channel, event]
                    )

    def play(self):
        start_time = 0
        self.__schedule()
        self.__sched.run()


def print_sch_event(channel, sch_event):
    print("@{} -- CH{} - {}".format(time.time(), channel, repr(sch_event)))

if __name__ == "__main__":
    seq = Sequencer()
    seq.set_callback(print_sch_event)

    seq.add_event(0, TimeUnit(0), NoteEvent(60, 64, TimeUnit(1)))
    seq.add_event(0, TimeUnit(2), NoteEvent(62, 64, TimeUnit(1)))
    # same event, should be ignored
    seq.add_event(0, TimeUnit(2), NoteEvent(62, 64, TimeUnit(1)))
    seq.add_event(1, TimeUnit(1, 2), NoteEvent(58, 64, TimeUnit(1)))
    seq.add_event(0, TimeUnit(1), NoteEvent(61, 64, TimeUnit(1)))
    # another (different) event, at same time
    seq.add_event(0, TimeUnit(1), NoteEvent(63, 64, TimeUnit(1)))

    seq.play()
