local view_module = require "core.view"

local M = {}

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assert_rect(ref, name)
	return assert(ref:rect(), "missing " .. name .. " rect")
end

local function test_intrinsic_component()
	local view = view_module.new {
		width = 200,
		height = 140,
	}
	local report = {}
	local root = view:mount("test/smoke/layout_intrinsic_root", {
		width = 200,
		height = 140,
		show = true,
		report = report,
	})

	view:update(0)

	local refs = assert(report.refs, "missing layout refs")
	local component = assert_rect(refs.component, "component")
	local header = assert_rect(refs.header, "header")
	local body = assert_rect(refs.body, "body")

	assert_equal(component.y, 0, "component should start at parent top")
	assert_equal(component.h, 74, "component wrapper should derive height from rendered header")
	assert_equal(header.y, 0, "header host should start at parent top")
	assert_equal(header.h, 74, "header host should keep explicit height")
	assert_equal(body.y, 74, "following sibling should be laid out after component intrinsic height")

	root.args.show = false
	view:update(0)
	body = assert_rect(refs.body, "body")
	assert_equal(refs.component:rect(), nil, "removed component ref should be cleared")
	assert_equal(refs.header:rect(), nil, "removed host ref should be cleared")
	assert_equal(body.y, 0, "following sibling should move up after component removal")
end

local function test_parent_size()
	local view = view_module.new {
		width = 200,
		height = 120,
	}
	local report = {}
	view:mount("test/smoke/layout_parent_size_root", {
		width = 200,
		height = 120,
		report = report,
	})

	view:update(0)

	local refs = assert(report.refs, "missing layout refs")
	local container = assert_rect(refs.container, "container")
	local component = assert_rect(refs.component, "component")
	local inner = assert_rect(refs.inner, "inner")

	assert_equal(container.x, 10, "container should respect root padding")
	assert_equal(container.y, 10, "container should respect root padding")
	assert_equal(container.w, 160, "container should keep explicit width")
	assert_equal(container.h, 80, "container should keep explicit height")
	assert_equal(component.x, container.x, "component should align to container x")
	assert_equal(component.y, container.y, "component should align to container y")
	assert_equal(component.w, container.w, "component should fill container width")
	assert_equal(component.h, container.h, "component should fill container height")
	assert_equal(inner.x, container.x, "inner host should align to container x")
	assert_equal(inner.y, container.y, "inner host should align to container y")
	assert_equal(inner.w, container.w, "inner host should fill container width")
	assert_equal(inner.h, container.h, "inner host should fill container height")
end

local function test_ref_rect_uses_owner_local_coordinates()
	local view = view_module.new {
		width = 200,
		height = 120,
	}
	local report = {}
	view:mount("test/smoke/ref_owner_root", {
		position = "absolute",
		left = 20,
		top = 10,
		report = report,
	})
	view:update(0)

	local rect = assert(report.child_ref:rect(), "missing component-owned child rect")
	assert_equal(rect.x, 6, "ref rect should be local to the owner component")
	assert_equal(rect.y, 4, "ref rect should ignore the owner component root offset")
	assert_equal(rect.w, 12, "ref rect should keep child width")
	assert_equal(rect.h, 8, "ref rect should keep child height")
end

local function test_direct_destroy_detaches_layout()
	local view = view_module.new {
		width = 200,
		height = 140,
	}
	local report = {}
	view:mount("test/smoke/layout_intrinsic_root", {
		width = 200,
		height = 140,
		show = true,
		report = report,
	})

	view:update(0)
	local refs = assert(report.refs, "missing layout refs")
	assert_equal(assert_rect(refs.body, "body").y, 74, "body should start below mounted component")

	assert(refs.component.current, "missing component instance"):destroy()
	view:update(0)
	assert_equal(refs.component:rect(), nil, "destroyed component ref should be cleared")
	assert_equal(refs.header:rect(), nil, "destroyed host ref should be cleared")
	assert_equal(assert_rect(refs.body, "body").y, 0, "body should move up after direct component destroy")
end

function M.run()
	test_intrinsic_component()
	test_parent_size()
	test_ref_rect_uses_owner_local_coordinates()
	test_direct_destroy_detaches_layout()
end

return M
