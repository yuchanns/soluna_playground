local icon = require "icon"
local view_module = require "core.view"

local M = {}

local FRAME_DT <const> = 1 / 60
local PAGE_PADDING <const> = 32
local CONTENT_WIDTH <const> = 1136
local CONTENT_HEIGHT <const> = 654
local SELECT_CLICK_X <const> = 38
local SELECT_OPEN_Y <const> = 525
local SELECT_LARGE_Y <const> = 643
local COMPACT_WIDTH <const> = 920

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

---@param width number
---@param height number
---@return number, number
local function content_origin(width, height)
	local content_width = math.min(math.max(width - PAGE_PADDING * 2, 0), CONTENT_WIDTH)
	local content_height = math.min(math.max(height - PAGE_PADDING * 2, 0), CONTENT_HEIGHT)
	return (width - content_width) * 0.5, (height - content_height) * 0.5
end

---@param args table
---@param width number
local function assert_select_large_clickable(args, width)
	local view = view_module.new {
		w = width,
		h = args.height,
	}
	local batch <const> = args.batch
	view:mount("components_showcase", {
		width = width,
		height = args.height,
	})

	frame(view, batch, FRAME_DT)

	local content_x, content_y = content_origin(width, args.height)
	click(view, batch, content_x + SELECT_CLICK_X, content_y + SELECT_OPEN_Y)
	frame(view, batch, 0.2)

	local target = view:click(content_x + SELECT_CLICK_X, content_y + SELECT_LARGE_Y)
	assert(target and target.args.value == "large", "third select option should be clickable")
	frame(view, batch, FRAME_DT)
end

---@param args table
---@param width number
local function assert_toggle_inside_card(args, width)
	local refs = {
		toggle_card = view_module.ref(),
		enabled_toggle = view_module.ref(),
		disabled_toggle = view_module.ref(),
	}
	local view = view_module.new {
		w = width,
		h = args.height,
	}
	view:mount("components_showcase", {
		width = width,
		height = args.height,
		refs = refs,
	})

	frame(view, args.batch, FRAME_DT)

	local card = assert(refs.toggle_card:rect(), "missing toggle card rect")
	local enabled = assert(refs.enabled_toggle:rect(), "missing enabled toggle rect")
	local disabled = assert(refs.disabled_toggle:rect(), "missing disabled toggle rect")
	local right = card.x + card.w
	assert(enabled.x >= card.x and enabled.x + enabled.w <= right, "enabled toggle should stay inside card")
	assert(disabled.x >= card.x and disabled.x + disabled.w <= right, "disabled toggle should stay inside card")
end

function M.run(args)
	icon.init "asset/icons.dl"

	assert_select_large_clickable(args, args.width)
	assert_toggle_inside_card(args, COMPACT_WIDTH)

	local wide_width = args.width + 400
	assert_select_large_clickable(args, wide_width)
end

return M
