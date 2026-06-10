local view = require "core.view"
local soluna_icon = require "soluna.icon"
local mattext = require "soluna.material.text"
local floor = math.floor

local args = ...

local function pixel(value)
	return floor(value + 0.5)
end

local current_name
local current_text

---@param name string
---@return string
local function icon_text(name)
	if name ~= current_name then
		local id = assert(soluna_icon.names[name], "missing icon " .. tostring(name))
		current_name = name
		current_text = "[i" .. tostring(id) .. "]"
	end
	return assert(current_text)
end

return function()
	local name = assert(args.name, "missing icon name")
	local text = icon_text(name)

	view.canvas({
		width = "100%",
		height = "100%",
	}, function(width, height)
		if width <= 0 or height <= 0 then
			return
		end

		local size = args.size or math.min(width, height)
		local color = assert(args.color, "missing icon color")
		local rotation = args.rotation or 0
		local font_resource = view.resource "font"
		local fontid = assert(font_resource.loaded).id
		local cobj = assert(font_resource.ptr)
		local block = mattext.block(cobj, fontid, size, color, "CV")
		local stream = block(text, pixel(width), pixel(height))

		if rotation ~= 0 then
			local cx = pixel(width / 2)
			local cy = pixel(height / 2)
			view.batch:layer(1, rotation, cx, cy)
			view.batch:add(stream, -cx, -cy)
			view.batch:layer()
		else
			view.batch:add(stream, 0, 0)
		end
	end)
end
