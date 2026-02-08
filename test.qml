import QtQuick
import QtQuick.Shapes

Window {
    id: root
    width: 800
    height: 600
    visible: true
    visibility: "FullScreen"

    signal userAction(var payload)

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real outerRadius: Math.min(width, height) * 0.35
    readonly property real innerRadius: outerRadius * 0.75
    readonly property real outerBatRadius: Math.min(width, height) * 0.5
    readonly property real inBatRadius: outerBatRadius * 0.75

    // Helper function: polar to cartesian
    function point(angleDeg, radius) {
        const rad = angleDeg * Math.PI / 180
        return Qt.point(
            centerX + Math.cos(rad) * radius,
            centerY - Math.sin(rad) * radius
        )
    }

    // Utility: build a sampled polygon (outer arc then inner arc reversed)
    function makeSectorPolygon(startDeg, endDeg, innerR, outerR, steps) {
        var poly = []
        var total = Math.max(3, steps || 40)
        var step = (endDeg - startDeg) / total
        // outer arc from start -> end
        for (var i = 0; i <= total; ++i) {
            var d = startDeg + i * step
            poly.push(point(d, outerR))
        }
        // inner arc from end -> start
        for (var j = 0; j <= total; ++j) {
            var d2 = endDeg - j * step
            poly.push(point(d2, innerR))
        }
        return poly
    }

    // Ray-casting point-in-polygon (standard) - expects polygon as array of Qt.point objects
    function pointInPolygon(pt, poly) {
        var x = pt.x, y = pt.y
        var inside = false
        for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            var xi = poly[i].x, yi = poly[i].y
            var xj = poly[j].x, yj = poly[j].y
            var intersect = ((yi > y) !== (yj > y)) &&
                            (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi)
            if (intersect) inside = !inside
        }
        return inside
    }

    // polygons for hit-testing (kept up-to-date by rebuildPolygons)
    property var e1Poly: []
    property var e2Poly: []
    property var e3Poly: []
    property var e4Poly: []
    property var eclairPoly: []

    // Recompute polygons (call when geometry or radii change)
    function rebuildPolygons() {
        e1Poly = makeSectorPolygon(e1.start_deg, e1.end_deg, innerRadius, outerRadius, 60)
        e2Poly = makeSectorPolygon(e2.start_deg, e2.end_deg, innerRadius, outerRadius, 60)
        e3Poly = makeSectorPolygon(e3.start_deg, e3.end_deg, innerRadius, outerRadius, 60)
        e4Poly = makeSectorPolygon(e4.start_deg, e4.end_deg, innerRadius, outerRadius, 60)

        // Eclair polygon built from the same points you used in the eclair ShapePath
        eclairPoly = [
            point(4, outerRadius),
            point(13, innerRadius),
            Qt.point(centerX, centerY),
            Qt.point(0.0669*width + centerX, centerY + 0.05*height),
            point(223, innerRadius),
            Qt.point(0.16*width + centerX, centerY + 0.055*height),
            Qt.point(0.1*width + centerX, centerY + 0.02*height)
        ]
    }

    function scheduleRebuild() {
        Qt.callLater(rebuildPolygons)
    }

    onWidthChanged: scheduleRebuild()
    onHeightChanged: scheduleRebuild()
    // when outer/inner radius changes, recompute too
    onOuterRadiusChanged: scheduleRebuild()
    onInnerRadiusChanged: scheduleRebuild()
    Component.onCompleted: scheduleRebuild()

    Shape {
        anchors.fill: parent

        // ---- Segment 1 ----
        ShapePath {
            id: e1

            fillColor: "#27428f"
            strokeColor: "#000000"

            property int start_deg: 4
            property int end_deg: 82
            property real sx: point(start_deg, outerRadius).x
            property real sy: point(start_deg, outerRadius).y

            startX: sx
            startY: sy

            PathArc {
                x: point(e1.end_deg, outerRadius).x
                y: point(e1.end_deg, outerRadius).y
                radiusX: outerRadius
                radiusY: outerRadius
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: point(e1.end_deg, innerRadius).x
                y: point(e1.end_deg, innerRadius).y
            }

            PathArc {
                x: point(13, innerRadius).x
                y: point(13, innerRadius).y
                radiusX: innerRadius
                radiusY: innerRadius
            }

            PathLine {
                x: e1.sx
                y: e1.sy
            }
        }

        // ---- Segment 2 ----
        ShapePath {
            id: e2

            fillColor: "#27428f"
            strokeColor: "#000000"

            property int start_deg: 82
            property int end_deg: 160
            property real sx: point(start_deg, outerRadius).x
            property real sy: point(start_deg, outerRadius).y

            startX: sx
            startY: sy

            PathArc {
                x: point(e2.end_deg, outerRadius).x
                y: point(e2.end_deg, outerRadius).y
                radiusX: outerRadius
                radiusY: outerRadius
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: point(e2.end_deg, innerRadius).x
                y: point(e2.end_deg, innerRadius).y
            }

            PathArc {
                x: point(e2.start_deg, innerRadius).x
                y: point(e2.start_deg, innerRadius).y
                radiusX: innerRadius
                radiusY: innerRadius
            }

            PathLine {
                x: e2.sx
                y: e2.sy
            }
        }


        // ---- Segment 3 ----
        ShapePath {
            id: e3

            fillColor: "#27428f"
            strokeColor: "#000000"

            property int start_deg: 160
            property int end_deg: 240
            property real sx: point(start_deg, outerRadius).x
            property real sy: point(start_deg, outerRadius).y

            startX: sx
            startY: sy

            PathArc {
                x: point(e3.end_deg, outerRadius).x
                y: point(e3.end_deg, outerRadius).y
                radiusX: outerRadius
                radiusY: outerRadius
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: point(e3.end_deg, innerRadius).x
                y: point(e3.end_deg, innerRadius).y
            }

            PathArc {
                x: point(e3.start_deg, innerRadius).x
                y: point(e3.start_deg, innerRadius).y
                radiusX: innerRadius
                radiusY: innerRadius
            }

            PathLine {
                x: e3.sx
                y: e3.sy
            }
        }

        // ---- Segment 4 ----
        ShapePath {
            id: e4

            fillColor: "#27428f"
            strokeColor: "#000000"

            property int start_deg: 240
            property int end_deg: 320
            property real sx: point(start_deg, outerRadius).x
            property real sy: point(start_deg, outerRadius).y

            startX: sx
            startY: sy

            PathArc {
                x: point(e4.end_deg, outerRadius).x
                y: point(e4.end_deg, outerRadius).y
                radiusX: outerRadius
                radiusY: outerRadius
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: point(e4.end_deg, innerRadius).x
                y: point(e4.end_deg, innerRadius).y
            }

            PathArc {
                x: point(e4.start_deg, innerRadius).x
                y: point(e4.start_deg, innerRadius).y
                radiusX: innerRadius
                radiusY: innerRadius
            }

            PathLine {
                x: e4.sx
                y: e4.sy
            }
        }

        // Eclair
        ShapePath {
            id: eclair

            fillColor: "#27428f"
            strokeColor: "#cee002"
            strokeWidth: 2

            property real sx: point(4, outerRadius).x
            property real sy: point(4, outerRadius).y

            startX: sx
            startY: sy

            // Point 2    
            PathLine {
                x: point(13, innerRadius).x
                y: point(13, innerRadius).y
            }
            // Point 3
            PathLine {
                x: centerX
                y: centerY
            }
            // Point 4
            PathLine {
                x: 0.0669*width + centerX
                y: centerY + 0.05*height
            }
            // Point 5
            PathLine {
                x: point(223, innerRadius).x
                y: point(223, innerRadius).y
            }
            // Point 6
            PathLine {
                x: 0.16*width + centerX
                y: centerY + 0.055*height
            }
            // Point 7
            PathLine {
                x: 0.1*width + centerX
                y: centerY + 0.02*height
            }

            PathLine {
                x: eclair.sx
                y: eclair.sy
            }
        }

        ShapePath {
            id: battery      
            
            fillGradient: ConicalGradient {
                centerX: root.centerX
                centerY: root.centerY

                angle: 120

                GradientStop { position: 0.0; color: "#20c50e" }
                GradientStop { position: 0.45; color: "#eeff00" }
                GradientStop { position: 5/6; color: "#c00a00" }
            }

            strokeColor: "#000000"

            property real sx: point(60, outerBatRadius).x
            property real sy: point(60, outerBatRadius).y
            property real end_deg: 60 - backend.batteryLevel * 300
            property bool largeArc: Math.abs(end_deg) > 120.0

            startX: sx
            startY: sy

            PathArc {
                x: point(battery.end_deg, outerBatRadius).x
                y: point(battery.end_deg, outerBatRadius).y
                radiusX: outerBatRadius
                radiusY: outerBatRadius
                useLargeArc: battery.largeArc
            }

            PathLine {
                x: point(battery.end_deg, inBatRadius).x
                y: point(battery.end_deg, inBatRadius).y
            }

            PathArc {
                x: point(60, inBatRadius).x
                y: point(60, inBatRadius).y
                radiusX: inBatRadius
                radiusY: inBatRadius
                direction: PathArc.Counterclockwise
                useLargeArc: battery.largeArc
            }

            PathLine {
                x: point(60, outerBatRadius).x
                y: point(60, outerBatRadius).y
            }
        }

        ShapePath {
            id: batteryBox      
            
            fillColor: "transparent"
            strokeColor: "#000000"
            strokeWidth: 2

            property real sx: point(60, outerBatRadius).x
            property real sy: point(60, outerBatRadius).y
            property real end_deg: -240

            startX: sx
            startY: sy

            PathArc {
                x: point(batteryBox.end_deg, outerBatRadius).x
                y: point(batteryBox.end_deg, outerBatRadius).y
                radiusX: outerBatRadius
                radiusY: outerBatRadius
                useLargeArc: true
            }

            PathLine {
                x: point(batteryBox.end_deg, inBatRadius).x
                y: point(batteryBox.end_deg, inBatRadius).y
            }

            PathArc {
                x: point(60, inBatRadius).x
                y: point(60, inBatRadius).y
                radiusX: inBatRadius
                radiusY: inBatRadius
                direction: PathArc.Counterclockwise
                useLargeArc: true
            }

            PathLine {
                x: point(60, outerBatRadius).x
                y: point(60, outerBatRadius).y
            }
        }
    }


    // A single MouseArea covering the window does hover + click hit testing
    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        property bool dragging: false
        property point pressPos
        property var visitedSegments: ({})   // set-like object

        readonly property int dragThreshold: 10

        property var lastClickedShape: null

        onClicked: {
            if (dragging)
                return   // ⬅️ prevent click logic after a drag
            var p = Qt.point(mouse.x, mouse.y)
            if (pointInPolygon(p, root.e1Poly)) {
                //console.log("Clicked: Segment 1")
                clickArea.lastClickedShape = e1
                e1.fillColor = "#123456"
            } else if (pointInPolygon(p, root.e2Poly)) {
                //console.log("Clicked: Segment 2")
                clickArea.lastClickedShape = e2
                e2.fillColor = "#123456"
            } else if (pointInPolygon(p, root.e3Poly)) {
                //console.log("Clicked: Segment 3")
                clickArea.lastClickedShape = e3
                e3.fillColor = "#123456"
            } else if (pointInPolygon(p, root.e4Poly)) {
                //console.log("Clicked: Segment 4")
                clickArea.lastClickedShape = e4
                e4.fillColor = "#123456"
            } else if (pointInPolygon(p, root.eclairPoly)) {
                //console.log("Clicked: Eclair")
                clickArea.lastClickedShape = eclair
                eclair.fillColor = "#123456"
            } else {
                //console.log("Clicked: background")
                clickArea.lastClickedShape = null
            }
        }

        onPressed: {
            dragging = false
            pressPos = Qt.point(mouse.x, mouse.y)
            visitedSegments = ({})
        }

        onPositionChanged: {
            if (!pressed)
                return

            var dx = mouse.x - pressPos.x
            var dy = mouse.y - pressPos.y

            if (!dragging && Math.sqrt(dx*dx + dy*dy) > dragThreshold) {
                dragging = true
            }

            if (dragging) {
                var p = Qt.point(mouse.x, mouse.y)
                var seg = segmentAtPoint(p)

                if (seg && !visitedSegments[seg]) {
                    visitedSegments[seg] = true

                    switch (seg) {
                    case "e1": e1.fillColor = "#ff8800"; break
                    case "e2": e2.fillColor = "#ff8800"; break
                    case "e3": e3.fillColor = "#ff8800"; break
                    case "e4": e4.fillColor = "#ff8800"; break
                    case "e5": eclair.fillColor = "#ff8800"; break
                    }

                    //console.log("Gesture touched:", seg)
                }
            }
        }

        onReleased: {
            var p = Qt.point(mouse.x, mouse.y)
            var seg = segmentAtPoint(p)


            if (!dragging && seg) {
                root.userAction({
                    type: "click",
                    segment: seg
                })
            } else if (dragging) {
                root.userAction({
                    type: "drag",
                    segments: Object.keys(visitedSegments)
                })
            }
        }

        function segmentAtPoint(p) {
            if (pointInPolygon(p, e1Poly)) return "e1"
            if (pointInPolygon(p, e2Poly)) return "e2"
            if (pointInPolygon(p, e3Poly)) return "e3"
            if (pointInPolygon(p, e4Poly)) return "e4"
            if (pointInPolygon(p, eclairPoly)) return "e5"
            return null
        }       

    }
}
