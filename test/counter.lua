local soluna = require "soluna"

local args = ...

local MOUSE_PRESS <const> = 1

soluna.set_window_title "Reactive Counter"

local view = require "core.view".new {
	w = args.width,
	h = args.height,
}

local C = {}

view:mount("counter", {
	w = 460,
	h = 300,
})

function C.window_resize(w, h)
	view:resize(w, h)
end

function C.mouse_move(x, y)
	view:pointer(x, y)
end

function C.mouse_button(_, state)
	if state ~= MOUSE_PRESS then
		return
	end
	view:click()
end

local batch = args.batch

function C.frame()
	view:update()

	view:draw(batch)
end

return C
