local view = require "core.view"

local args = ...
local report <const> = assert(args.report)
local child_ref <const> = view.ref()

report.child_ref = child_ref

return function()
	view.box({
		width = 40,
		height = 30,
		padding = "4 0 0 6",
	}, function()
		view.box {
			ref = child_ref,
			width = 12,
			height = 8,
		}
	end)
end
