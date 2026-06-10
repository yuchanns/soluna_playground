local soluna = require "soluna"
local icon = require "icon"

local args = ...

soluna.set_window_title "Component Showcase"
icon.init "asset/icons.dl"

local view = require "core.view".new {
	w = args.width,
	h = args.height,
}

local C = {}
local FRAME_DT <const> = 1 / 60

local root = view:mount("components_showcase", {
	width = args.width,
	height = args.height,
})

function C.window_resize(w, h)
	view:resize(w, h)
	root.args.width = w
	root.args.height = h
end

function C.mouse_move(x, y)
	view:pointer(x, y)
end

function C.mouse_button(button, state)
	view:mouse_button(button, state)
end

local batch = args.batch

function C.frame()
	view:update(FRAME_DT)

	view:draw(batch)
end

return C
