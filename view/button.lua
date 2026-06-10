local view = require "core.view"

local args = ...

local label <const> = assert(args.label)
local width <const> = args.width or 120
local height <const> = args.height or 36
local text_size <const> = args.text_size or 16
local background <const> = args.background or 0xffe5e7eb
local hover_background <const> = args.hover_background or 0xffd1d5db
local pressed_background <const> = args.pressed_background or 0xff9ca3af
local disabled_background <const> = args.disabled_background or 0xfff3f4f6
local text_color <const> = args.text_color or 0xff111827
local disabled_text_color <const> = args.disabled_text_color or 0xff9ca3af
local icon_size <const> = args.icon_size or 16
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
		width = width,
		height = height,
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
		view.hbox({
			width = "100%",
			height = "100%",
			alignItems = "center",
			justify = "center",
			padding = args.padding or "0 12 0 12",
			gap = args.gap or 8,
		}, function()
			if args.icon then
				view.mount("view/icon", {
					width = icon_size,
					height = "100%",
					name = args.icon,
					size = icon_size,
					color = color,
				})
			end
			view.text(label, {
				flex = 1,
				height = "100%",
				size = text_size,
				color = color,
				align = "CV",
			})
			if args.icon_right then
				view.mount("view/icon", {
					width = icon_size,
					height = "100%",
					name = args.icon_right,
					size = icon_size,
					color = color,
				})
			end
		end)
	end)
end
