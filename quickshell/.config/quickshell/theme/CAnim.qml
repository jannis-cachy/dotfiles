import QtQuick

// ColorAnimation with a Motion type, effects curves suit colors
ColorAnimation {
    property string type: "slowEffects"

    duration: Motion.duration(type)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.curve(type)
}
