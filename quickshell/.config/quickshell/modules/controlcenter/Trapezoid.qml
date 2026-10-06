import QtQuick
import QtQuick.Shapes
import "../../theme"

// Parallelogram with rounded corners: top edge spans [slant, width], bottom edge [0, width - slant]
Item {
    id: root

    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    // Side angle in degrees, 0 is a plain rectangle
    property real angle: 15
    // Corner radius in px
    property real radius: 0

    readonly property real slant: Math.min(height * Math.tan(angle * Math.PI / 180), width / 2)

    // Rounded polygon as svg path, each corner is cut back by d and joined with a circular arc
    function outline(w, h, s, r) {
        const pts = [[s, 0], [w, 0], [w - s, h], [0, h]];
        const n = pts.length;
        if (r <= 0.01)
            return "M" + pts.map(p => p[0] + " " + p[1]).join(" L") + " Z";
        let d = "";
        for (let i = 0; i < n; i++) {
            const p = pts[(i + n - 1) % n], c = pts[i], q = pts[(i + 1) % n];
            let ax = p[0] - c[0], ay = p[1] - c[1], bx = q[0] - c[0], by = q[1] - c[1];
            const la = Math.hypot(ax, ay), lb = Math.hypot(bx, by);
            ax /= la; ay /= la; bx /= lb; by /= lb;
            const half = Math.acos(Math.max(-1, Math.min(1, ax * bx + ay * by))) / 2;
            const cut = Math.min(r / Math.tan(half), la / 2, lb / 2);
            const rr = cut * Math.tan(half);
            d += (i === 0 ? "M" : " L") + (c[0] + ax * cut) + " " + (c[1] + ay * cut)
                + " A" + rr + " " + rr + " 0 0 1 " + (c[0] + bx * cut) + " " + (c[1] + by * cut);
        }
        return d + " Z";
    }

    // Hit test so hover and clicks follow the slanted sides. Pass hitMask (not the item)
    // to a child MouseArea, Qt shifts points by the position of an item used as a mask.
    property QtObject hitMask: QtObject {
        function contains(p: point): bool {
            if (p.y < 0 || p.y > root.height)
                return false;
            const t = root.height > 0 ? p.y / root.height : 0;
            const left = root.slant * (1 - t);
            return p.x >= left && p.x <= root.width - root.slant * t;
        }
    }
    containmentMask: hitMask

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth > 0 ? root.borderWidth : -1

            PathSvg {
                path: root.outline(root.width, root.height, root.slant, root.radius)
            }
        }
    }
}
