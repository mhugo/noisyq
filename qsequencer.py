# Qt interface to sequencer

from sequencer import Sequencer, TimeUnit

from PyQt5.QtCore import (
    pyqtSignal, pyqtSlot, QObject
)

class QSequencer(QObject):

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__seq = Sequencer()

    @pyqtSlot(int, int, int, int, result=list)
    def listEvents(self,
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


