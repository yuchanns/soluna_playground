local view = require "core.view"

local args = ...
local case <const> = args.case

if case == "setup_dependency" then
	local report <const> = assert(args.report)
	local initial_value <const> = args.value

	return function()
		report.child_initial = initial_value
		view.box({
			width = 10,
			height = 10,
		})
	end
end

if case == "clickable_props" then
	view.clickable {
		enabled = args.enabled,
		on_click = args.on_click,
	}

	return function()
		view.box({
			width = args.width,
			height = args.height,
		})
	end
end

if case == "draw_props" then
	return function()
		view.box({
			width = "100%",
			height = "100%",
		})
	end
end

local report <const> = assert(args.report)

return function()
	local value <const> = args.value
	view.canvas({
		width = args.width,
		height = args.height,
		value = value,
	}, function()
		report.canvas_draws = report.canvas_draws + 1
	end)
end
