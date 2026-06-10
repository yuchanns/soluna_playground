local app = require "soluna.app"
local icon = require "icon"
local soluna = require "soluna"

local args = ...

soluna.set_window_title "Showcase Interaction Test"
icon.init "asset/icons.dl"

local view = require "core.view".new {
	w = args.width,
	h = args.height,
}

local FRAME_DT <const> = 1 / 60
local batch <const> = args.batch

view:mount("components_showcase", {
	width = args.width,
	height = args.height,
})

local function frame(dt)
	view:update(dt)
	view:draw(batch)
end

local function click(x, y)
	view:pointer(x, y)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	frame(FRAME_DT)
end

local C = {}

function C.frame()
	frame(FRAME_DT)

	click(70, 557)
	frame(0.2)

	local target = view:click(70, 675)
	assert(target and target.args.value == "large", "third select option should be clickable")
	frame(FRAME_DT)

	app.quit()
end

return C
