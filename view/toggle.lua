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
local checked_progress = view.animated(function()
	return args.checked and 1 or 0
end, {
	duration = 0.16,
	easing = "out_cubic",
})
local hover_progress = view.animated(function()
	return (hovered() or pressed()) and 1 or 0
end, {
	duration = 0.1,
	easing = "out_cubic",
})

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
	local checked = checked_progress()
	local hover = hover_progress()
	local off_fill = view.lerp_color(off_background, off_hover_background, hover)
	local on_fill = view.lerp_color(on_background, on_hover_background, hover)
	local fill = view.lerp_color(off_fill, on_fill, checked)

	if not enabled then
		fill = disabled_background
	end

	local knob_left = view.lerp(4, width - knob_size - 4, checked)

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
			radius = height * 0.5,
		})
		view.mount("view/surface", {
			position = "absolute",
			left = knob_left,
			top = 4,
			width = knob_size,
			height = knob_size,
			fill = knob_color,
			radius = knob_size * 0.5,
		})
	end)
end
