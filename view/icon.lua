local view = require "core.view"
local soluna_icon = require "soluna.icon"
local mattext = require "soluna.material.text"
local floor = math.floor

local args = ...

local function pixel(value)
	return floor(value + 0.5)
end

return function()
	view.canvas({
		width = "100%",
		height = "100%",
	}, function(width, height)
		if width <= 0 or height <= 0 then
			return
		end

		local name = assert(args.name, "missing icon name")
		local size = args.size or math.min(width, height)
		local color = assert(args.color, "missing icon color")
		local font_resource = view.resource "font"
		local fontid = assert(font_resource.loaded).id
		local cobj = assert(font_resource.ptr)
		local block = mattext.block(cobj, fontid, size, color, "CV")
		local id = assert(soluna_icon.names[name], "missing icon " .. tostring(name))
		local stream = block("[i" .. tostring(id) .. "]", pixel(width), pixel(height))

		view.batch:add(stream, 0, 0)
	end)
end
