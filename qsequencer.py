# Qt interface to sequencer

from sequencer import Sequencer, TimeUnit, NoteOnEvent, NoteOffEvent

from PyQt5.QtCore import (
    pyqtSignal, pyqtSlot, QObject, QTimer, QElapsedTimer
)

class QSequencer(QObject):

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__seq = Sequencer()

        self.__timer = QTimer()
        self.__timer.setSingleShot(True)
        self.__timer.timeout.connect(self.__on_timeout)

        self.__elapsed_timer = QElapsedTimer()

        self.__events = []
        self.__event = None
        self.__bpm = 120
        # elasped time in ms since the beginning of play()
        self.__elapsed_ms = 0

    noteOn = pyqtSignal(int, int, int, arguments=["channel", "note", "velocity"])
    noteOff = pyqtSignal(int, int, arguments=["channel", "note"])

    @pyqtSlot(int, int, int, int, result=list)
    def list_events(self,
                   start_time: int, start_time_unit: int,
                   stop_time: int, stop_time_unit: int):
        return [
            {
                "channel": channel,
                "time_amount": event_time.amount,
                "time_unit": event_time.unit,
                "event": event.to_dict()
            }
            for channel, event_time, event in self.__seq.iterate_events(
                    TimeUnit(start_time, start_time_unit),
                    TimeUnit(stop_time, stop_time_unit)
            )
        ]

    def __on_timeout(self):
        # We rearm the timeout. Make sure self.__event is copied
        # otherwise it could be overwritten while not processed yet
        events = list(self.__event)
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
        if self.__events:
            if not self.__event:
                e_ms = 0
                self.__elapsed_timer.start()
            else:
                e_ms = self.__elapsed_timer.elapsed()
            e = self.__events.pop(0)
            event_time, self.__event = e
            next_ms = int(event_time.amount() * 60 * 1000 / event_time.unit() / self.__bpm)
            self.__timer.start(next_ms - e_ms)
            

    @pyqtSlot(int)
    def play(self, bpm):
        # TODO: add start_time, stop_time
        self.__bpm = bpm
        self.__events = list(self.__seq.iterate_scheduled_events())
        #print("\n".join([repr(e) for e in self.__events]))
        self.__event = None
        self.__arm_next_event()
