local view = require "core.view"

local args = ...

local w <const> = assert(args.width)
local h <const> = assert(args.height)
local label <const> = assert(args.label)
local color <const> = args.color or 0xff4f7cff
local hover_color <const> = args.hover_color or color
local text_color <const> = args.text_color or 0xffffffff
local text_size <const> = args.text_size or 18

local hovered = view.hovered()
local pressed = view.pressed()

view.clickable(args)

return function()
	view.box({
		width = w,
		height = h,
		background = function()
			if pressed() then
				return hover_color
			end
			if hovered() then
				return hover_color
			end
			return color
		end,
	}, function()
		view.text(label, {
			width = "100%",
			height = "100%",
			size = text_size,
			color = text_color,
			align = "CV",
		})
	end)
end
