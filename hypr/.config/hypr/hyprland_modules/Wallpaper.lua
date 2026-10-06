local S = require("hyprland_modules/Settings")

local M = {}

-- Writes a hyprpaper config from the wallpapers saved in settings.json.
-- Returns the hyprpaper command, plain "hyprpaper" (hyprpaper.conf) when nothing is saved.
function M.command()
	if next(S.wallpapers) == nil then
		return "hyprpaper"
	end
	local out = { "splash = false\n" }
	-- empty monitor is the fallback for outputs without an own entry (laptop screen)
	local _, first = next(S.wallpapers)
	out[#out + 1] = string.format("wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n", first)
	for monitor, path in pairs(S.wallpapers) do
		out[#out + 1] = string.format("wallpaper {\n    monitor = %s\n    path = %s\n    fit_mode = cover\n}\n", monitor, path)
	end
	local conf = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprpaper.conf"
	local file = io.open(conf, "w")
	if not file then
		return "hyprpaper"
	end
	file:write(table.concat(out))
	file:close()
	return "hyprpaper -c " .. conf
end

return M
