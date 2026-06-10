local view = require "core.view"

local args = ...

local id <const> = assert(args.id)
local label <const> = assert(args.label)
local marker <const> = args.marker or ""
local icon <const> = args.icon
local width <const> = args.width or 220
local height <const> = args.height or 40
local text_size <const> = args.text_size or 16
local icon_size <const> = args.icon_size or 16
local background <const> = args.background
local hover_background <const> = args.hover_background or 0xffeef2ff
local active_background <const> = args.active_background or 0xffdbeafe
local text_color <const> = args.text_color or 0xff374151
local active_text_color <const> = args.active_text_color or 0xff1d4ed8
local marker_color <const> = args.marker_color or 0xff2563eb
local radius <const> = args.radius or 4

local hovered = view.hovered()
local pressed = view.pressed()

view.clickable {
	enabled = args.enabled,
	on_click = function(event)
		if args.on_select then
			args.on_select(id, event)
		end
	end,
}

return function()
	local active = args.active == true
	local fill = background
	local color = text_color

	if active then
		fill = active_background
		color = active_text_color
	elseif pressed() then
		fill = active_background
		color = active_text_color
	elseif hovered() then
		fill = hover_background
	end

	view.box({
		width = width,
		height = height,
	}, function()
		if fill then
			view.mount("view/surface", {
				position = "absolute",
				left = 0,
				top = 0,
				width = "100%",
				height = "100%",
				fill = fill,
				radius = radius,
			})
		end
		view.hbox({
			width = "100%",
			height = "100%",
			alignItems = "center",
			padding = 8,
			gap = 8,
		}, function()
			if icon then
				view.mount("view/icon", {
					width = 22,
					height = "100%",
					name = icon,
					size = icon_size,
					color = marker_color,
				})
			else
				view.text(marker, {
					width = 22,
					height = "100%",
					size = text_size,
					color = marker_color,
					align = "CV",
				})
			end
			view.text(label, {
				flex = 1,
				height = "100%",
				size = text_size,
				color = color,
				align = "LV",
			})
		end)
	end)
end
