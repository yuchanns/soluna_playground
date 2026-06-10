local view = require "core.view"

local args = ...

local value <const> = assert(args.value)
local label <const> = assert(args.label)
local width <const> = args.width or "100%"
local height <const> = args.height or 34
local text_size <const> = args.text_size or 15
local background <const> = args.background
local hover_background <const> = args.hover_background or 0xffeff6ff
local selected_background <const> = args.selected_background or 0xffdbeafe
local text_color <const> = args.text_color or 0xff374151
local selected_text_color <const> = args.selected_text_color or 0xff1d4ed8

local hovered = view.hovered()
local pressed = view.pressed()

view.clickable {
	enabled = args.enabled,
	on_click = function(event)
		if args.on_select then
			args.on_select(value, event)
		end
	end,
}

return function()
	local selected = args.selected == true
	local fill = background
	local color = text_color

	if selected then
		fill = selected_background
		color = selected_text_color
	elseif pressed() then
		fill = selected_background
		color = selected_text_color
	elseif hovered() then
		fill = hover_background
	end

	view.box({
		width = width,
		height = height,
		background = fill,
		padding = 10,
	}, function()
		view.text(label, {
			width = "100%",
			height = "100%",
			size = text_size,
			color = color,
			align = "LV",
		})
	end)
end
