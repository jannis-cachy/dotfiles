pragma Singleton
import QtQuick
import Quickshell

// Motion tokens taken from caelestia-shell (Material 3 expressive). Curves are BezierSpline
// points, each segment is control1, control2, end. Durations drop to 0 with animations off.
Singleton {
    readonly property bool enabled: Theme.animations.enabled

    readonly property var curves: ({
            emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1],
            emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1],
            emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1],
            standard: [0.2, 0, 0, 1, 1, 1],
            standardAccel: [0.3, 0, 1, 1, 1, 1],
            standardDecel: [0, 0, 0, 1, 1, 1],
            fastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1],
            defaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1],
            slowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1],
            fastEffects: [0.31, 0.94, 0.34, 1, 1, 1],
            defaultEffects: [0.34, 0.8, 0.34, 1, 1, 1],
            slowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
        })

    // Anim type to curve and duration in ms, same pairs as caelestia's Anim enum.
    // Spatial curves overshoot (movement, size), effects do not (opacity, color).
    readonly property var types: ({
            standardSmall: ["standard", 200],
            standard: ["standard", 400],
            standardLarge: ["standard", 600],
            emphasizedSmall: ["emphasized", 200],
            emphasized: ["emphasized", 400],
            emphasizedLarge: ["emphasized", 600],
            fastSpatial: ["fastSpatial", 350],
            defaultSpatial: ["defaultSpatial", 500],
            slowSpatial: ["slowSpatial", 650],
            fastEffects: ["fastEffects", 150],
            defaultEffects: ["defaultEffects", 200],
            slowEffects: ["slowEffects", 300],
            // Menu open (Reveal), kept short so it never feels like waiting
            revealFade: ["fastEffects", 90],
            revealGrow: ["fastSpatial", 160]
        })

    // Hyprland leaf, curve, ms, style, taken from caelestia's hypr/hyprland/animations.lua.
    // Layers fade instead of their slide, each menu is its own window here and Reveal animates the content.
    // 0 ms turns a leaf off. Theme.hyprApply pushes these, Hyprland takes single segment beziers only.
    readonly property var hyprLeaves: [["windowsIn", "emphasizedDecel", 500, ""], ["windowsOut", "emphasizedAccel", 300, ""], ["windowsMove", "standard", 400, ""] /* Frame.qml leftBand uses the same */, ["workspaces", "standard", 0, ""], ["fade", "standard", 250, ""], ["fadeDim", "standard", 250, ""], ["border", "standard", 600, ""], ["layersIn", "emphasizedDecel", 150, "fade"], ["layersOut", "emphasizedAccel", 100, "fade"]]

    function hyprLua() {
        const used = {};
        let lua = "";
        hyprLeaves.forEach(([leaf, key, ms, style]) => {
            if (curves[key].length !== 6)
                key = "standard";
            if (!used[key]) {
                const c = curves[key];
                lua += 'hl.curve("m3' + key + '", { type = "bezier", points = { {' + c[0] + ', ' + c[1] + '}, {' + c[2] + ', ' + c[3] + '} } }) ';
                used[key] = true;
            }
            // Hyprland speed is in 100ms steps
            lua += 'hl.animation({ leaf = "' + leaf + '", enabled = ' + (ms > 0) + ', speed = ' + Math.max(1, ms / 100) + ', bezier = "m3' + key + '"' + (style ? ', style = "' + style + '"' : '') + ' }) ';
        });
        return lua;
    }

    function duration(type) {
        return enabled ? (types[type] ?? types.standard)[1] : 0;
    }

    function curve(type) {
        return curves[(types[type] ?? types.standard)[0]];
    }
}
