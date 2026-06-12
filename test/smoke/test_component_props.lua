local view_module = require "core.view"

local M = {}

local FRAME_DT <const> = 1 / 60

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assert_true(value, message)
	if not value then
		error(message, 2)
	end
end

local function click(view, x, y)
	view:pointer(x, y)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	view:update(FRAME_DT)
end

local function batch()
	local out = {
		layers = {},
	}

	function out:layer(...)
		local args = table.pack(...)
		self.layers[#self.layers + 1] = args
	end

	function out.add() end

	return out
end

local function has_layer_x(batch_out, x)
	for i = 1, #batch_out.layers do
		local args = batch_out.layers[i]
		if args.n >= 2 and args[1] == x and args[2] == 0 then
			return true
		end
	end
	return false
end

local function test_batched_effects_compile_root_once()
	local view = view_module.new {
		width = 80,
		height = 20,
	}
	local report = {
		canvas_draws = 0,
	}
	local root = view:mount("test/smoke/component_props_root", {
		case = "batched_compile",
		width = 80,
		height = 20,
		a = 1,
		b = 1,
		report = report,
	})

	view:update(0)
	local baseline <const> = report.canvas_draws

	root.args.a = 2
	root.args.b = 2
	view:update(0)

	---@diagnostic disable-next-line: preferred-local-alias
	local draw_delta <const> = report.canvas_draws - baseline
	assert_equal(draw_delta, 2, "batched child effects should compile the root once")
end

local function test_setup_reads_do_not_subscribe_parent_render()
	local view = view_module.new {
		width = 80,
		height = 20,
	}
	local report = {}
	view:mount("test/smoke/component_props_root", {
		case = "setup_dependency",
		x = 0,
		y = 0,
		width = 80,
		height = 20,
		report = report,
	})

	local previous_renders = report.parent_renders

	assert_true(report.child ~= nil, "setup dependency test should expose the child instance")
	report.child.args.value = 2
	view:update(0)

	assert_equal(report.parent_renders, previous_renders, "child setup props should not reschedule the parent render")
end

local function test_clickable_uses_patched_props()
	local view = view_module.new {
		width = 80,
		height = 40,
	}
	local report = {
		clicks = 0,
		last_action = 0,
	}
	view:mount("test/smoke/component_props_root", {
		case = "clickable_props",
		report = report,
	})

	view:update(0)
	click(view, 8, 8)
	assert_equal(report.clicks, 1, "clickable should receive the initial click")
	assert_equal(report.last_action, 1, "clickable should use the initial callback")

	report.set_enabled(false)
	view:update(0)
	click(view, 8, 8)
	assert_equal(report.clicks, 1, "disabled patched clickable should not receive clicks")

	report.set_enabled(true)
	report.set_action(2)
	view:update(0)
	click(view, 8, 8)
	assert_equal(report.clicks, 2, "re-enabled patched clickable should receive clicks")
	assert_equal(report.last_action, 2, "clickable should use the patched callback")
end

local function test_clickable_binds_omitted_props()
	local view = view_module.new {
		width = 80,
		height = 40,
	}
	local report = {
		clicks = 0,
	}
	view:mount("test/smoke/component_props_root", {
		case = "clickable_optional_props",
		report = report,
	})

	view:update(0)
	click(view, 8, 8)
	assert_equal(report.clicks, 1, "clickable should default to enabled when the prop is omitted")

	report.set_enabled(false)
	view:update(0)
	click(view, 8, 8)
	assert_equal(report.clicks, 1, "omitted setup clickable enabled prop should bind to later false patches")
end

local function test_component_node_uses_patched_draw_props()
	local view = view_module.new {
		width = 80,
		height = 40,
	}
	local root = view:mount("test/smoke/component_props_root", {
		case = "draw_props",
		offset = 7,
	})

	view:update(0)
	local first = batch()
	view:draw(first)
	assert_true(has_layer_x(first, 7), "component translateX should affect the wrapper layer")

	root.args.offset = 13
	view:update(0)
	local second = batch()
	view:draw(second)
	assert_true(has_layer_x(second, 13), "patched component translateX should affect the wrapper layer")
end

function M.run()
	test_batched_effects_compile_root_once()
	test_setup_reads_do_not_subscribe_parent_render()
	test_clickable_uses_patched_props()
	test_clickable_binds_omitted_props()
	test_component_node_uses_patched_draw_props()
end

return M
