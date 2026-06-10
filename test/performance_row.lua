local view = require "core.view"

local args = ...

local index <const> = assert(args.index)
---@type ViewValue<integer>
local value <const> = assert(args.value)
local width <const> = args.width or "100%"
local height <const> = args.height or 24
local text_color <const> = 0xff111827
local muted <const> = 0xff6b7280
local odd_background <const> = 0xffffffff
local even_background <const> = 0xfff9fafb
local highlight_background <const> = 0xffdbeafe

return function()
	local count = value()
	local fill = index % 2 == 0 and even_background or odd_background
	if count % 10 == 0 and count > 0 then
		fill = highlight_background
	end

	view.hbox({
		width = width,
		height = height,
		background = fill,
		alignItems = "center",
		padding = "0 10 0 10",
		gap = 10,
	}, function()
		view.text("#" .. tostring(index), {
			width = 76,
			height = "100%",
			size = 13,
			color = muted,
			align = "LV",
		})
		view.text("Benchmark row " .. tostring(index), {
			flex = 1,
			height = "100%",
			size = 13,
			color = text_color,
			align = "LV",
		})
		view.text("value " .. tostring(count), {
			width = 120,
			height = "100%",
			size = 13,
			color = text_color,
			align = "RV",
		})
	end)
end
