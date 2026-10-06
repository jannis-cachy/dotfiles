local S = require("hyprland_modules/Settings")

hl.config({
	input = {
		kb_layout = "de,us",
		kb_options = "grp:alt_shift_toggle",
		numlock_by_default = false,
		follow_mouse = 1,
		sensitivity = 0.0,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
		},
	},
})
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
hl.device({
	name = "sonix-usb-device", -- Speedlink ORIOS, exact name from hyprctl devices
	sensitivity = S.mouse.sensitivity,
	scroll_factor = S.mouse.scrollFactor,
})
hl.device({
	name = "weylus-stylus", -- exact name from hyprctl devices
	output = "DP-1", -- the monitor you capture in Weylus
})
