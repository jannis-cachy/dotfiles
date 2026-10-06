import QtQuick

// NumberAnimation with a Motion type, e.g. Anim { type: "fastSpatial" }
NumberAnimation {
    property string type: "defaultSpatial"

    duration: Motion.duration(type)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve(type)
}
