local S = require("hyprland_modules/Settings")

hl.config({
	general = {
		gaps_in = S.hypr.gapsIn,
		gaps_out = S.hypr.gapsOut,
		border_size = S.hypr.borderSize,

		col = {
			active_border = S.colors.focus,
			-- active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
			inactive_border = "rgba(00000000)",
		},

		resize_on_border = true,
		allow_tearing = false,
		layout = "master",

		snap = {
			enabled = true,
			respect_gaps = false,
		},
	},
})
