local icon = require "icon"
local view_module = require "core.view"

local M = {}

local FRAME_DT <const> = 1 / 60

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function click(view, x, y)
	view:pointer(x, y)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	view:update(FRAME_DT)
end

function M.run(args)
	icon.init "asset/icons.dl"

	local view = view_module.new {
		width = 400,
		height = 320,
	}
	local events = {
		button = 0,
		nav = "overview",
		toggle = false,
		open = false,
		select = "small",
	}
	view:mount("test/smoke/component_interaction_root", {
		width = 400,
		height = 320,
		events = events,
	})

	view:update(FRAME_DT)
	view:draw(args.batch)

	click(view, 32, 32)
	assert_equal(events.button, 1, "button should receive click")
	view:draw(args.batch)

	click(view, 32, 82)
	assert_equal(events.nav, "settings", "nav item should receive click")
	view:draw(args.batch)

	click(view, 32, 126)
	assert_equal(events.toggle, true, "toggle should receive click")
	view:draw(args.batch)

	click(view, 32, 166)
	assert_equal(events.open, true, "select trigger should open menu")
	view:update(0.2)
	view:draw(args.batch)

	click(view, 32, 253)
	assert_equal(events.select, "medium", "select option should receive click")
	view:draw(args.batch)

	click(view, 32, 166)
	assert_equal(events.open, true, "select trigger should reopen menu")
	view:update(0.2)
	view:draw(args.batch)

	click(view, 32, 290)
	assert_equal(events.select, "large", "third select option should receive click")
	view:update(0.3)
	view:pointer(8, 8)
	view:draw(args.batch)
end

return M
