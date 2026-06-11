local soluna = require "soluna"
local font = require "core.font"
local icon = require "icon"
local mattext = require "soluna.material.text"
local sfont = require "soluna.font"

return function(args)
	soluna.set_window_title "Component Showcase"
	icon.init "asset/icons.dl"

	local view = require "core.view".new {
		w = args.width,
		h = args.height,
	}

	local C = {}
	local FRAME_DT <const> = 1 / 60
	local HUD_W <const> = 180
	local HUD_H <const> = 24
	local PAGE_PADDING <const> = 32
	local CONTENT_WIDTH <const> = 1136
	local CONTENT_HEIGHT <const> = 654
	local MUTED <const> = 0xff6b7280
	---@type { w: number, h: number }
	local screen = {
		w = args.width,
		h = args.height,
	}
	local fontid <const> = assert(font.load()).id
	local stats_text <const> = mattext.block(sfont.cobj(), fontid, 14, MUTED, "RV")
	local stats_count = -1
	local stats_label

	local root = view:mount("components_showcase", {
		width = args.width,
		height = args.height,
	})

	function C.window_resize(w, h)
		screen.w = w
		screen.h = h
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

	local function draw_statistics()
		local render_count = view:statistics().render_count
		if render_count ~= stats_count then
			stats_count = render_count
			stats_label = stats_text("View renders: " .. tostring(render_count), HUD_W, HUD_H)
		end
		local content_width = math.min(math.max(screen.w - PAGE_PADDING * 2, 0), CONTENT_WIDTH)
		local content_x = (screen.w - content_width) * 0.5
		local content_height = math.min(math.max(screen.h - PAGE_PADDING * 2, 0), CONTENT_HEIGHT)
		local content_y = (screen.h - content_height) * 0.5
		local x = content_x + content_width - HUD_W
		batch:add(stats_label, math.max(x, 0), content_y + 7)
	end

	function C.frame()
		view:update(FRAME_DT)

		view:draw(batch)
		draw_statistics()
	end

	return C
end
