hl.monitor({
	output = "DP-1",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1.0,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "1920x0",
	scale = 1.0,
})

-- Laptop panel
hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1.0 })

-- Any other machine (laptop): every unknown output at its preferred mode
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })

-- Cursor starts on the left screen
hl.config({ cursor = { default_monitor = "DP-1" } })
