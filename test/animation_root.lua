local view = require "core.view"

local args = ...
local report <const> = assert(args.report)

local animated = view.animated(function()
	return args.on and 1 or 0
end, {
	duration = 1,
	easing = "linear",
})

return function()
	report.animated = animated()
	report.transition_mounted = false
	report.transition_progress = nil
	report.transition_phase = nil

	view.transition({
		show = args.show,
		width = 20,
		height = 20,
		duration = 1,
		easing = "linear",
	}, function(state)
		report.transition_mounted = true
		report.transition_progress = state.progress
		report.transition_phase = state.phase

		view.box {
			width = "100%",
			height = "100%",
			background = 0xff2563eb,
		}
	end)
end
