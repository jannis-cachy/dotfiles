local S = require("hyprland_modules/Settings")
local Wallpaper = require("hyprland_modules/Wallpaper")

-- hyprland.start fires once per session, so reloads and reopened workspaces do not respawn apps
hl.on("hyprland.start", function()
	hl.exec_cmd(Wallpaper.command())
	-- Without it quickshell starts on the first keybind (Binaries/qsc) or notification (dbus package)
	if S.autostart.quickshell then
		hl.exec_cmd("quickshell")
	end
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	if S.autostart.enabled then
		hl.exec_cmd("kitty", { workspace = "1 silent" })
		hl.exec_cmd("firefox", { workspace = "2 silent" })
		hl.exec_cmd("kitty -e nvim", { workspace = "4 silent" })
	end
end)
