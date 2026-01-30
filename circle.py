# main.py
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
import sys

class Controller(QObject):
    levelChanged = Signal()
    chargingChanged = Signal()

    def __init__(self):
        super().__init__()
        self._level = 0                   # 0..100
        self._charging = False
        self._timer = QTimer(self)
        self._timer.setInterval(80)       # tick every 80 ms when charging/discharging
        self._timer.timeout.connect(self._tick)

    def _tick(self):
        # increment (charging) or decrement (not charging) until bounds
        if self._charging:
            if self._level < 100:
                self._level += 1
                self.levelChanged.emit()
            else:
                self._charging = False
                self.chargingChanged.emit()
                self._timer.stop()
        else:
            # if not charging and timer runs (used for auto-discharge demo), decrement
            if self._level > 0:
                self._level -= 1
                self.levelChanged.emit()
            else:
                self._timer.stop()

    @Property(int, notify=levelChanged)
    def level(self):
        return self._level

    @Slot(int)
    def setLevel(self, v):
        v = max(0, min(100, int(v)))
        if v != self._level:
            self._level = v
            self.levelChanged.emit()

    @Property(bool, notify=chargingChanged)
    def charging(self):
        return self._charging

    @Slot()
    def startCharging(self):
        if not self._charging:
            self._charging = True
            self.chargingChanged.emit()
            if not self._timer.isActive():
                self._timer.start()

    @Slot()
    def stopCharging(self):
        if self._charging:
            self._charging = False
            self.chargingChanged.emit()
            # keep timer running if you want automatic discharge; otherwise stop timer
            # self._timer.stop()

    @Slot()
    def toggleCharging(self):
        if self._charging:
            self.stopCharging()
        else:
            self.startCharging()


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    ctrl = Controller()
    engine.rootContext().setContextProperty("controller", ctrl)

    engine.load("circle.qml")
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
