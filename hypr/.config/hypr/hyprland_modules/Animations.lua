local S = require("hyprland_modules/Settings")

-- Master switch from settings.json, Theme.qml flips it live with hyprctl eval.
-- The curves below are only a fallback: while quickshell runs it pushes the ones from
-- theme/Motion.qml (hyprLua) on start, on settings changes and after every Hyprland reload.
hl.config({ animations = { enabled = S.animations.enabled } })

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Speeds are in 100ms steps, kept short
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "almostLinear", style = "popin 90%" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quick" })
-- Layer surfaces are the quickshell windows (launcher, control center, popups, frame)
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "almostLinear", style = "fade" })
-- The special workspace (ALT + G) slides by default, it just appears instead
hl.animation({ leaf = "specialWorkspace", enabled = false })
