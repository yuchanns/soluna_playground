local view = require "core.view"
local rounded_rect = require "playground.material.rounded_rect"

local floor = math.floor

local args = ...

local function pixel(value)
	return floor(value + 0.5)
end

return function()
	local fill = assert(args.fill or args.background, "missing surface fill")
	local radius = args.radius or 0
	local border = args.border or fill
	local border_width = args.border_width or 0

	view.canvas({
		width = "100%",
		height = "100%",
	}, function(width, height)
		if width <= 0 or height <= 0 then
			return
		end

		view.batch:add(rounded_rect.rect {
			width = pixel(width),
			height = pixel(height),
			radius = pixel(radius),
			fill = fill,
			border = border,
			border_width = pixel(border_width),
		}, 0, 0)
	end)
end
