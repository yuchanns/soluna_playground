local view = require "core.view"

local args = ...
local refs <const> = assert(args.refs)

return function()
	view.box({
		width = args.width,
		height = args.height,
		padding = 10,
	}, function()
		view.box({
			ref = refs.container,
			width = 160,
			height = 80,
			background = 0xfff3f4f6,
		}, function()
			view.mount("test/smoke/layout_parent_size_child", {
				ref = refs.component,
				width = "100%",
				height = "100%",
				inner_ref = refs.inner,
			})
		end)
	end)
end
