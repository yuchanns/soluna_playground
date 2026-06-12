local view = require "core.view"

local args = ...
local case <const> = args.case

if case == "setup_dependency" then
	local report <const> = assert(args.report)
	local value = view.value(1)

	report.set_value = function(next_value)
		value(next_value)
	end

	return function()
		report.parent_renders = (report.parent_renders or 0) + 1
		report.child = view.mount("test/smoke/component_props_child", {
			case = "setup_dependency",
			value = value(),
			report = report,
		})
	end
end

if case == "clickable_props" then
	local report <const> = assert(args.report)
	local enabled = view.value(true)
	local action = view.value(1)

	report.set_enabled = function(next_enabled)
		enabled(next_enabled)
	end
	report.set_action = function(next_action)
		action(next_action)
	end

	return function()
		local action_id = action()
		view.mount("test/smoke/component_props_child", {
			case = "clickable_props",
			width = 40,
			height = 24,
			enabled = enabled(),
			on_click = function()
				report.clicks = report.clicks + 1
				report.last_action = action_id
			end,
		})
	end
end

if case == "clickable_optional_props" then
	local report <const> = assert(args.report)
	local enabled = view.value(nil)

	report.set_enabled = function(next_enabled)
		enabled(next_enabled)
	end

	return function()
		local child_props = {
			case = "clickable_props",
			width = 40,
			height = 24,
			on_click = function()
				report.clicks = report.clicks + 1
			end,
		}
		local enabled_value = enabled()
		if enabled_value ~= nil then
			child_props.enabled = enabled_value
		end
		view.mount("test/smoke/component_props_child", child_props)
	end
end

if case == "draw_props" then
	return function()
		view.mount("test/smoke/component_props_child", {
			case = "draw_props",
			width = 20,
			height = 10,
			translateX = args.offset,
		})
	end
end

return function()
	view.hbox({
		width = args.width,
		height = args.height,
	}, function()
		view.mount("test/smoke/component_props_child", {
			case = "batched_compile",
			key = "a",
			width = 10,
			height = 10,
			value = args.a,
			report = args.report,
		})
		view.mount("test/smoke/component_props_child", {
			case = "batched_compile",
			key = "b",
			width = 10,
			height = 10,
			value = args.b,
			report = args.report,
		})
	end)
end
