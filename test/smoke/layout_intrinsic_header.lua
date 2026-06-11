local view = require "core.view"

local args = ...

return function()
	view.hbox {
		ref = args.header_ref,
		width = "100%",
		height = 74,
		background = 0xff2563eb,
	}
end
