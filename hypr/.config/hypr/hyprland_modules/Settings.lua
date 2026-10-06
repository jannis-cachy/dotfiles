-- Reads ~/.config/quickshell/settings.json, falls back to defaults on any error
local path = (os.getenv("HOME") or "") .. "/.config/quickshell/settings.json"

local defaults = {
	rounding = 8,
	wallpapers = {},
	autostart = {
		enabled = true,
		quickshell = true,
	},
	animations = {
		enabled = false,
	},
	mouse = {
		sensitivity = 0,
		scrollFactor = 1.0,
	},
	font = {
		iconTheme = "Papirus-Dark",
		cursorTheme = "Bibata-Modern-Ice",
		cursorSize = 24,
	},
	colors = {
		focus = "#d92323",
	},
	hypr = {
		gapsIn = 2,
		gapsOut = 15,
		borderSize = 2,
	},
}

-- Minimal JSON decoder (objects, arrays, strings, numbers, booleans, null)
local function decode(str)
	local pos = 1

	local function skip()
		pos = str:find("%S", pos) or #str + 1
	end

	local parse_value

	local function parse_string()
		local out = {}
		pos = pos + 1
		while true do
			local c = str:sub(pos, pos)
			if c == "" then
				error("unterminated string")
			elseif c == '"' then
				pos = pos + 1
				return table.concat(out)
			elseif c == "\\" then
				local e = str:sub(pos + 1, pos + 1)
				local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
				if e == "u" then
					out[#out + 1] = utf8.char(tonumber(str:sub(pos + 2, pos + 5), 16))
					pos = pos + 6
				else
					out[#out + 1] = map[e] or e
					pos = pos + 2
				end
			else
				out[#out + 1] = c
				pos = pos + 1
			end
		end
	end

	local function parse_container(close, on_item)
		pos = pos + 1
		skip()
		if str:sub(pos, pos) == close then
			pos = pos + 1
			return
		end
		while true do
			skip()
			on_item()
			skip()
			local c = str:sub(pos, pos)
			pos = pos + 1
			if c == close then
				return
			elseif c ~= "," then
				error("expected , or " .. close)
			end
		end
	end

	function parse_value()
		skip()
		local c = str:sub(pos, pos)
		if c == "{" then
			local obj = {}
			parse_container("}", function()
				local key = parse_string()
				skip()
				if str:sub(pos, pos) ~= ":" then
					error("expected :")
				end
				pos = pos + 1
				obj[key] = parse_value()
			end)
			return obj
		elseif c == "[" then
			local arr = {}
			parse_container("]", function()
				arr[#arr + 1] = parse_value()
			end)
			return arr
		elseif c == '"' then
			return parse_string()
		end
		for word, val in pairs({ ["true"] = true, ["false"] = false }) do
			if str:sub(pos, pos + #word - 1) == word then
				pos = pos + #word
				return val
			end
		end
		if str:sub(pos, pos + 3) == "null" then
			pos = pos + 4
			return nil
		end
		local num = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
		if not num or num == "" then
			error("unexpected character at " .. pos)
		end
		pos = pos + #num
		return tonumber(num)
	end

	return parse_value()
end

-- Copies user values over defaults, keeping the default when the type differs
local function merge(base, user)
	if type(user) ~= "table" then
		return base
	end
	for k, v in pairs(base) do
		if type(v) == "table" and next(v) == nil and type(user[k]) == "table" then
			-- free-form table such as wallpapers, keep the user keys
			base[k] = user[k]
		elseif type(v) == "table" then
			base[k] = merge(v, user[k])
		elseif type(user[k]) == type(v) then
			base[k] = user[k]
		end
	end
	return base
end

local settings = defaults
local file = io.open(path, "r")
if file then
	local content = file:read("*a")
	file:close()
	local ok, data = pcall(decode, content)
	if ok then
		settings = merge(defaults, data)
	end
end

return settings
