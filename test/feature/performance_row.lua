local view = require "core.view"

local args = ...
local value <const> = assert(args.value)

return function()
	local n = value()
	local fill = args.index % 2 == 0 and 0xffffffff or 0xfff9fafb
	if n % 5 == 0 and n > 0 then
		fill = 0xffdbeafe
	end

	view.hbox({
		width = args.width,
		height = args.height,
		background = fill,
		alignItems = "center",
		padding = "0 10 0 10",
		gap = 12,
	}, function()
		view.text("#" .. tostring(args.index), {
			width = 80,
			height = "100%",
			size = 13,
			color = 0xff6b7280,
			align = "LV",
		})
		view.text("value: " .. tostring(n), {
			flex = 1,
			height = "100%",
			size = 13,
			color = 0xff111827,
			align = "LV",
		})
	end)
end
