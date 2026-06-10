local view = require "core.view"

local value = view.value
local args = ...
local C = args.dispatch()

local w <const> = assert(args.width)
local h <const> = assert(args.height)
local label <const> = assert(args.label)
local color <const> = args.color or 0xff4f7cff
local hover_color <const> = args.hover_color or color
local text_color <const> = args.text_color or 0xffffffff
local text_size <const> = args.text_size or 18
local on_click <const> = args.on_click

local hover = value(false)

local function inside(x, y)
	return x ~= nil and y ~= nil and x >= 0 and x <= w and y >= 0 and y <= h
end

function C.pointer(x, y)
	hover(inside(x, y))
end

function C.click(x, y)
	if inside(x, y) and on_click then
		on_click()
	end
end

return function()
	view.box({
		width = w,
		height = h,
		background = function()
			return hover() and hover_color or color
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
