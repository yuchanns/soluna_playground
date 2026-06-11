local view_module = require "core.view"

local M = {}

local function assert_range(value, min, max, message)
	if value < min or value > max then
		error(message .. ": expected " .. tostring(min) .. ".." .. tostring(max) .. ", got " .. tostring(value), 2)
	end
end

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

function M.run()
	local view = view_module.new {
		width = 120,
		height = 120,
	}
	local report = {}
	local root = view:mount("test/smoke/animation_root", {
		width = 120,
		height = 120,
		on = false,
		show = false,
		report = report,
	})

	view:update(0)
	assert_equal(report.animated, 0, "animated should start at target")
	assert_equal(report.transition_mounted, false, "hidden transition should not mount children")

	root.args.on = true
	view:update(0)
	assert_equal(report.animated, 0, "animated should retarget without jumping")
	view:update(0.5)
	assert_range(report.animated, 0.49, 0.51, "animated should advance by dt")

	root.args.on = false
	view:update(0)
	view:update(0.25)
	assert_range(report.animated, 0.36, 0.39, "animated should retarget from current value")

	root.args.show = true
	view:update(0)
	assert_equal(report.transition_mounted, true, "shown transition should mount children")
	assert_range(report.transition_progress, 0, 0.01, "transition should enter from zero")
	view:update(0.5)
	assert_range(report.transition_progress, 0.49, 0.51, "transition should advance enter progress")

	root.args.show = false
	view:update(0)
	assert_equal(report.transition_mounted, true, "leaving transition should keep children mounted")
	view:update(1)
	assert_equal(report.transition_mounted, false, "left transition should unmount children")
end

return M
