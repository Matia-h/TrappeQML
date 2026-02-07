import sys
from PySide6.QtCore import QObject, Slot, Property, Signal, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QJSValue


class Backend(QObject):
    batteryLevelChanged = Signal()

    def __init__(self):
        super().__init__()
        self._batteryLevel = 0

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

    @Slot(object)
    def handleUserAction(self, payload):

        # Convert JS object → Python dict
        if isinstance(payload, QJSValue):
            payload = payload.toVariant()

        action_type = payload.get("type")

        if action_type == "click":
            segment = payload["segment"]
            print(f"CLICK on {segment}")

        elif action_type == "drag":
            segments = payload["segments"]
            print(f"DRAG sequence: {segments}")


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.load("test.qml")

    root = engine.rootObjects()[0]

    root.userAction.connect(backend.handleUserAction)

     # Use QTimer to update battery level periodically
    counter = [0]  # Use list to modify in closure
    
    def update_battery():
        if counter[0] < 101:
            backend.setBatteryLevel(counter[0] / 100.0)
            counter[0] += 1
        else:
            timer.stop()
    
    timer = QTimer()
    timer.timeout.connect(update_battery)
    timer.start(100)
    
    sys.exit(app.exec())