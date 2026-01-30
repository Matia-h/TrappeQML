// main.qml
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: win
    width: 380
    height: 520
    visible: true
    title: "Charge Circle (0–100%)"

    // displayedLevel is animated for smooth visual transitions between controller.level changes
    property real displayedLevel: 0

    // animate displayedLevel whenever it is assigned a new value
    Behavior on displayedLevel {
        NumberAnimation { duration: 480; easing.type: Easing.InOutQuad }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18
        width: parent.width

        Item {
            width: parent.width
            height: 280

            // The canvas draws a background ring and a pie-sector fill proportional to displayedLevel
            Canvas {
                id: gauge
                anchors.horizontalCenter: parent.horizontalCenter
                width: 260
                height: 260
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    // devicePixelRatio aware
                    var ratio = devicePixelRatio;
                    var w = width;
                    var h = height;
                    ctx.canvas.width = Math.round(w * ratio);
                    ctx.canvas.height = Math.round(h * ratio);
                    ctx.scale(ratio, ratio);

                    var cx = w/2;
                    var cy = h/2;
                    var radius = Math.min(w,h) * 0.45;
                    var innerRadius = radius * 0.68;

                    // draw subtle background circle
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius + 6, 0, Math.PI*2);
                    ctx.fillStyle = "rgba(0,0,0,0.06)";
                    ctx.fill();
                    ctx.closePath();

                    // track (outline ring)
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, Math.PI*2);
                    ctx.lineWidth = 12;
                    ctx.strokeStyle = "rgba(0,0,0,0.12)";
                    ctx.stroke();
                    ctx.closePath();

                    // filled pie sector from -90deg
                    var start = -Math.PI/2;
                    var end = start + (displayedLevel / 100) * Math.PI * 2;

                    // color depends on level: green (high) -> yellow -> red (low)
                    var hue = Math.round((displayedLevel / 100) * 120); // 0..120
                    var color = "hsl(" + hue + ", 85%, 45%)";

                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, radius - 6, start, end, false);
                    ctx.closePath();
                    ctx.fillStyle = color;
                    ctx.fill();

                    // inner circle to create donut / ring look
                    ctx.beginPath();
                    ctx.arc(cx, cy, innerRadius, 0, Math.PI*2);
                    ctx.fillStyle = "white";
                    ctx.fill();
                    ctx.closePath();

                    // thin inner ring
                    ctx.beginPath();
                    ctx.arc(cx, cy, innerRadius, 0, Math.PI*2);
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = "rgba(0,0,0,0.05)";
                    ctx.stroke();
                    ctx.closePath();

                    // percentage text — drawn from QML Text element below, so we skip drawing text here
                }

                // repaint when the animated displayedLevel updates
                onDisplayedLevelChanged: requestPaint()
                Component.onCompleted: requestPaint()
            }

            // centered textual overlay for percentage
            Text {
                id: percentText
                anchors.horizontalCenter: gauge.horizontalCenter
                anchors.verticalCenter: gauge.verticalCenter
                text: Math.round(displayedLevel) + "%"
                font.pixelSize: 36
                font.bold: true
                color: "#222"
            }
        }

        // slider for direct control
        Slider {
            id: slider
            from: 0; to: 100; stepSize: 1
            value: controller.level
            onMoved: {
                controller.setLevel(value)
            }
            onPressed: controller.stopCharging()
            onReleased: controller.setLevel(value)
            Layout.margins: 18
            Layout.fillWidth: true
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Button {
                text: controller.charging ? "Stop charging" : "Start charging"
                onClicked: controller.toggleCharging()
                checkable: false
            }

            Button {
                text: "Set 0%"
                onClicked: controller.setLevel(0)
            }

            Button {
                text: "Set 100%"
                onClicked: controller.setLevel(100)
            }
        }

        // small helper text
        Text {
            text: "Use the slider or Start charging to see the circle fill.\nThe fill color moves from red → yellow → green as level increases."
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width * 0.9
            color: "#555"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // react to controller.level changes and assign to displayedLevel (so it animates)
    Connections {
        target: controller
        onLevelChanged: {
            // assign new value to the animated displayedLevel property
            win.displayedLevel = controller.level
            // keep the slider in sync
            slider.value = controller.level
        }
    }

    // initialize displayedLevel from controller value at startup
    Component.onCompleted: displayedLevel = controller.level
}
