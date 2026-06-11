local view = require "core.view"

local args = ...

return function()
	view.box {
		ref = args.inner_ref,
		width = "100%",
		height = "100%",
		background = 0xff2563eb,
	}
end
