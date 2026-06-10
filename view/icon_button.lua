local view = require "core.view"

local args = ...

local name <const> = assert(args.name, "missing icon button name")
local size <const> = args.size or args.width or args.height or 36
local icon_size <const> = args.icon_size or size - 16
local background <const> = args.background or 0xffe5e7eb
local hover_background <const> = args.hover_background or 0xffdbeafe
local pressed_background <const> = args.pressed_background or 0xffbfdbfe
local disabled_background <const> = args.disabled_background or 0xfff3f4f6
local text_color <const> = args.text_color or 0xff1f2937
local disabled_text_color <const> = args.disabled_text_color or 0xff9ca3af
local radius <const> = args.radius or 6

local hovered = view.hovered()
local pressed = view.pressed()

view.clickable {
	enabled = args.enabled,
	on_click = args.on_click,
}

return function()
	local enabled = args.enabled ~= false
	local fill = background
	local color = text_color

	if not enabled then
		fill = disabled_background
		color = disabled_text_color
	elseif pressed() then
		fill = pressed_background
	elseif hovered() then
		fill = hover_background
	end

	view.box({
		width = size,
		height = size,
	}, function()
		view.mount("view/surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = fill,
			radius = radius,
		})
		view.mount("view/icon", {
			width = "100%",
			height = "100%",
			name = name,
			size = icon_size,
			color = color,
		})
	end)
end
