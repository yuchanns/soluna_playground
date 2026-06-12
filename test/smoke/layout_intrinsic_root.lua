local view = require "core.view"

local args = ...
local refs <const> = {
	component = view.ref(),
	header = view.ref(),
	body = view.ref(),
}
assert(args.report).refs = refs

return function()
	view.vbox({
		width = args.width,
		height = args.height,
	}, function()
		if args.show ~= false then
			view.mount("test/smoke/layout_intrinsic_header", {
				ref = refs.component,
				width = "100%",
				header_ref = refs.header,
			})
		end

		view.box {
			ref = refs.body,
			width = "100%",
			height = 20,
			background = 0xffdbeafe,
		}
	end)
end
