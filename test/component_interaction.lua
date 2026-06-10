local app = require "soluna.app"
local icon = require "icon"
local soluna = require "soluna"

soluna.set_window_title "Component Interaction Test"
icon.init "asset/icons.dl"

local view = require "core.view".new {
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

view:mount("test/component_interaction_root", {
	width = 400,
	height = 320,
	events = events,
})

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function click(x, y)
	view:pointer(x, y)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	view:update()
end

local C = {}

function C.frame()
	view:update()

	click(32, 32)
	assert_equal(events.button, 1, "button should receive click")

	click(32, 82)
	assert_equal(events.nav, "settings", "nav item should receive click")

	click(32, 126)
	assert_equal(events.toggle, true, "toggle should receive click")

	click(32, 166)
	assert_equal(events.open, true, "select trigger should open menu")

	click(32, 253)
	assert_equal(events.select, "medium", "select option should receive click")

	app.quit()
end

return C
