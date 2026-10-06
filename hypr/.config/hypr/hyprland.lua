local S = require("hyprland_modules/Settings")

hl.config({
	decoration = {
		blur = {
			enabled = true,
			size = 8,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
		},
	},
})

require("hyprland_modules/Monitors")
require("hyprland_modules/Input")
require("hyprland_modules/Generals")
require("hyprland_modules/Keybinds")
require("hyprland_modules/Layouts")
require("hyprland_modules/Decorations")
require("hyprland_modules/Animations")
require("hyprland_modules/autostart")
require("hyprland_modules/Rules")
require("hyprland_modules/misc")

hl.env("QS_ICON_THEME", S.font.iconTheme)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", S.font.cursorTheme)
hl.env("XCURSOR_SIZE", tostring(S.font.cursorSize))
hl.env("HYPRCURSOR_THEME", S.font.cursorTheme)
hl.env("HYPRCURSOR_SIZE", tostring(S.font.cursorSize))
