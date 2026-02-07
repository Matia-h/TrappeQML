import sys
from PySide6.QtCore import QObject, Slot, Property, Signal, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QJSValue
from enum import Enum


class AppState(Enum):
    LOCKED = "locked"
    UNLOCKED = "unlocked"


class Backend(QObject):
    batteryLevelChanged = Signal()
    stateChanged = Signal(str)

    def __init__(self):
        super().__init__()
        self._batteryLevel = 0
        self.state = AppState.LOCKED
        self.pin_buffer = []


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


    @Slot(object)
    def handleUserAction(self, payload):

        payload = payload.toVariant()
        action_type = payload.get("type")

        if self.state == AppState.LOCKED:
            self._handle_locked(action_type, payload)

        elif self.state == AppState.UNLOCKED:
            self._handle_unlocked(action_type, payload)


    def _handle_locked(self, action_type, payload):
        if action_type != "click":
            return

        segment = payload["segment"]
        self.pin_buffer.append(segment)

        PIN_CODE = ["e1", "e3", "e2", "e4"]
        PIN_LENGTH = len(PIN_CODE)

        # Do NOTHING until PIN length reached
        if len(self.pin_buffer) < PIN_LENGTH:
            return

        # Now we have full PIN → validate
        if self.pin_buffer == PIN_CODE:
            print("🔓 UNLOCKED")
            self.state = AppState.UNLOCKED
            self.stateChanged.emit(self.state.value)
        else:
            print("❌ WRONG PIN")

        # Always reset buffer
        self.pin_buffer.clear()
        

    def _handle_unlocked(self, action_type, payload):

        if action_type == "click":
            seg = payload["segment"]

            if seg == "e1":
                print("Open settings")
            elif seg == "e2":
                print("Toggle battery view")
            elif seg == "e3":
                print("Next screen")
            elif seg == "e4":
                print("Previous screen")

        elif action_type == "drag":
            segments = payload["segments"]

            if segments == ["e5", "e1", "e2", "e3", "e4"]:
                self._charge_battery()

    
    def _charge_battery(self):
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


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.load("test.qml")

    root = engine.rootObjects()[0]

    root.userAction.connect(backend.handleUserAction)
    
    sys.exit(app.exec())