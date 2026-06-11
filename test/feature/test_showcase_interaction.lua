local icon = require "icon"
local view_module = require "core.view"

local M = {}

local FRAME_DT <const> = 1 / 60

local function frame(view, batch, dt)
	view:update(dt)
	view:draw(batch)
end

local function click(view, batch, x, y)
	view:pointer(x, y)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	frame(view, batch, FRAME_DT)
end

function M.run(args)
	icon.init "asset/icons.dl"

	local view = view_module.new {
		w = args.width,
		h = args.height,
	}
	local batch <const> = args.batch
	view:mount("components_showcase", {
		width = args.width,
		height = args.height,
	})

	frame(view, batch, FRAME_DT)

	click(view, batch, 70, 557)
	frame(view, batch, 0.2)

	local target = view:click(70, 675)
	assert(target and target.args.value == "large", "third select option should be clickable")
	frame(view, batch, FRAME_DT)
end

return M
