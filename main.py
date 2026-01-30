import sys
from PySide6.QtCore import QObject, Slot, Property, Signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


class Backend(QObject):
    batteryLevelChanged = Signal()

    def __init__(self):
        super().__init__()
        self._batteryLevel = 1

    def getBatteryLevel(self):
        return self._batteryLevel

    def setBatteryLevel(self, value):
        value = max(0.0, min(1.0, value))  # clamp 0–1
        if self._batteryLevel != value:
            self._batteryLevel = value
            self.batteryLevelChanged.emit()

    batteryLevel = Property(
        float,
        getBatteryLevel,
        setBatteryLevel,
        notify=batteryLevelChanged
    )

    @Slot(str)
    def onSegmentClicked(self, segment_id):
        print(f"Python received click on: {segment_id}")


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.load("main.qml")

    root = engine.rootObjects()[0]

    root.segmentClicked.connect(backend.onSegmentClicked)

    sys.exit(app.exec())