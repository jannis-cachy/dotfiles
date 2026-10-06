-- Workspaces 1-5 live on DP-1 (left), 6-9 on HDMI-A-1 (right), only pinned on the PC (hostname cachyosDual)
local f = io.open("/etc/hostname")
local host = f and f:read("*l") or ""
if f then
	f:close()
end
local pinned = host == "cachyosDual"
if pinned then
	for i = 1, 5 do
		hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = (i == 1) })
	end
	for i = 6, 10 do
		hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", default = (i == 6) })
	end
end
hl.window_rule({
	name = "no-border-when-only-window",
	match = {
		float = false,
		workspace = "w[tv1]",
	},
	border_size = 0,
})

-- Tray apps land on a fixed workspace, "silent" so just opening them doesn't steal focus.
-- SysTray.qml switches to that workspace when its tray icon is clicked.
hl.window_rule({
	name = "steam-workspace",
	match = { class = "^(steam)$" },
	workspace = "5 silent",
})
hl.window_rule({
	name = "obs-workspace",
	match = { class = "^(obs)$" },
	workspace = "7 silent",
})

-- Blur behind the app launcher
hl.layer_rule({
	name = "launcher-blur",
	match = {
		namespace = "launcher",
	},
	blur = true,
})

-- Blur the whole screen behind the control center (full screen backdrop window)
hl.layer_rule({
	name = "controlcenter-blur",
	match = {
		namespace = "controlcenter-blur",
	},
	blur = true,
})

