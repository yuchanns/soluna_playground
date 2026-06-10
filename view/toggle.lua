local view = require "core.view"

local args = ...

local width <const> = args.width or 54
local height <const> = args.height or 28
local knob_size <const> = args.knob_size or 20
local off_background <const> = args.off_background or 0xffd1d5db
local off_hover_background <const> = args.off_hover_background or 0xffcbd5e1
local on_background <const> = args.on_background or 0xff2563eb
local on_hover_background <const> = args.on_hover_background or 0xff1d4ed8
local disabled_background <const> = args.disabled_background or 0xffe5e7eb
local knob_color <const> = args.knob_color or 0xffffffff

local hovered = view.hovered()
local pressed = view.pressed()

view.clickable {
	enabled = args.enabled,
	on_click = function(event)
		if args.on_change then
			args.on_change(args.checked ~= true, event)
		end
	end,
}

return function()
	local enabled = args.enabled ~= false
	local checked = args.checked == true
	local fill = checked and on_background or off_background

	if not enabled then
		fill = disabled_background
	elseif hovered() or pressed() then
		fill = checked and on_hover_background or off_hover_background
	end

	---@type number
	local knob_left = 4
	if checked then
		knob_left = width - knob_size - 4
	end

	view.box({
		width = width,
		height = height,
		background = fill,
	}, function()
		view.box {
			position = "absolute",
			left = knob_left,
			top = 4,
			width = knob_size,
			height = knob_size,
			background = knob_color,
		}
	end)
end
