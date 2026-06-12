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
local BUTTON_CLICK_X <const> = 38
local BUTTON_CLICK_Y <const> = 231
local PAGE_EMPTY_X <const> = 10
local PAGE_EMPTY_Y <const> = 10

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
	view:mount("test/feature/components_showcase", {
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
local function assert_select_closes_after_other_card_click(args, width)
	local view = view_module.new {
		w = width,
		h = args.height,
	}
	local batch <const> = args.batch
	view:mount("test/feature/components_showcase", {
		width = width,
		height = args.height,
	})

	frame(view, batch, FRAME_DT)

	local content_x, content_y = content_origin(width, args.height)
	click(view, batch, content_x + SELECT_CLICK_X, content_y + SELECT_OPEN_Y)
	frame(view, batch, 0.2)

	click(view, batch, content_x + BUTTON_CLICK_X, content_y + BUTTON_CLICK_Y)
	local target = view:click(content_x + SELECT_CLICK_X, content_y + SELECT_LARGE_Y)
	assert(not (target and target.args and target.args.value == "large"),
		"select menu should close after another card click")
	frame(view, batch, FRAME_DT)
end

---@param args table
---@param width number
local function assert_select_closes_after_empty_page_click(args, width)
	local view = view_module.new {
		w = width,
		h = args.height,
	}
	local batch <const> = args.batch
	view:mount("test/feature/components_showcase", {
		width = width,
		height = args.height,
	})

	frame(view, batch, FRAME_DT)

	local content_x, content_y = content_origin(width, args.height)
	click(view, batch, content_x + SELECT_CLICK_X, content_y + SELECT_OPEN_Y)
	frame(view, batch, 0.2)

	click(view, batch, PAGE_EMPTY_X, PAGE_EMPTY_Y)
	local target = view:click(content_x + SELECT_CLICK_X, content_y + SELECT_LARGE_Y)
	assert(not (target and target.args and target.args.value == "large"),
		"select menu should close after empty page click")
	frame(view, batch, FRAME_DT)
end

---@param args table
---@param width number
function M.run(args)
	icon.init "asset/icons.dl"

	assert_select_large_clickable(args, args.width)
	assert_select_closes_after_other_card_click(args, args.width)
	assert_select_closes_after_empty_page_click(args, args.width)

	local wide_width = args.width + 400
	assert_select_large_clickable(args, wide_width)
end

return M
