import QtQuick
import QtQuick.Shapes

// Concave corner piece: the area between two frame edges and a circle (radius = size) that
// touches both. Drawn for topLeft and mirrored, the frame sides overlap the frame by 1px
// so their anti-aliased edges never show.
Item {
    id: root

    // Corner of this item that touches both frame edges
    property string corner: "topLeft"
    property real size: 0
    property color color: "transparent"

    readonly property bool atLeft: corner === "topLeft" || corner === "bottomLeft"
    readonly property bool atTop: corner === "topLeft" || corner === "topRight"

    width: size
    height: size
    visible: size > 0

    transform: Scale {
        origin.x: root.size / 2
        origin.y: root.size / 2
        xScale: root.atLeft ? 1 : -1
        yScale: root.atTop ? 1 : -1
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            startX: -1
            startY: -1
            PathLine {
                x: root.size
                y: -1
            }
            PathLine {
                x: root.size
                y: 0
            }
            PathArc {
                x: 0
                y: root.size
                radiusX: root.size
                radiusY: root.size
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: -1
                y: root.size
            }
            PathLine {
                x: -1
                y: -1
            }
        }
    }
}
