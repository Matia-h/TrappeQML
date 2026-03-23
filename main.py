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
    pinFailed = Signal()

    def __init__(self):
        super().__init__()
        self._batteryLevel = 0
        self.state = AppState.LOCKED
        self.pin_buffer = []

        self._batteryTimer = QTimer()
        self._batteryTimer.timeout.connect(self._update_battery)

        self._batteryDirection = 0   # +1 = charging, -1 = discharging


    def getBatteryLevel(self):
        return self._batteryLevel
    

    def setBatteryLevel(self, value):
        value = max(0.0, min(1.0, value))  # clamp 0–1
        if self._batteryLevel != value:
            self._batteryLevel = value
            self.batteryLevelChanged.emit()

    def _update_battery(self):
        step = 0.01 * self._batteryDirection

        new_value = self._batteryLevel + step

        # Clamp and stop at limits
        if new_value >= 1.0:
            self.setBatteryLevel(1.0)
            self._batteryTimer.stop()
        elif new_value <= 0.0:
            self.setBatteryLevel(0.0)
            self._batteryTimer.stop()
        else:
            self.setBatteryLevel(new_value)


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

        if self.pin_buffer == PIN_CODE:
            print("🔓 UNLOCKED")
            self.state = AppState.UNLOCKED
            self.stateChanged.emit(self.state.value)
        else:
            print("❌ WRONG PIN")
            self.pinFailed.emit()

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
            elif segments == ["e4","e3","e2","e1","e5"]:
                self._discharge_battery()

    
    def _charge_battery(self):
        self._batteryTimer.stop()
        self._batteryDirection = 1
        self._batteryTimer.start(100)

    def _discharge_battery(self):
        self._batteryTimer.stop()
        self._batteryDirection = -1
        self._batteryTimer.start(200)  # slower discharge feels more natural


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)

    engine.load("test.qml")

    root = engine.rootObjects()[0]

    root.userAction.connect(backend.handleUserAction)
    
    sys.exit(app.exec())