local view = require "core.view"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"

local BUTTON_W <const> = 96
local BUTTON_H <const> = 48
local BUTTON_GAP <const> = 40
local BUTTON_TEXT_SIZE <const> = 18

local value = view.value
local computed = view.computed
local args = ...

local w <const> = assert(args.w)
local h <const> = assert(args.h)
local ctrl_w <const> = BUTTON_W * 2 + BUTTON_GAP
local ctrl_x <const> = (w - ctrl_w) / 2
local ctrl_y <const> = h - 90

local minus_rect = {
	x = ctrl_x,
	y = ctrl_y,
	w = BUTTON_W,
	h = BUTTON_H,
}

local plus_rect = {
	x = ctrl_x + BUTTON_W + BUTTON_GAP,
	y = ctrl_y,
	w = BUTTON_W,
	h = BUTTON_H,
}

local count = value(0)

local blocks = computed(function()
	local font = view.resource "font"
	local fontid = assert(font.loaded).id
	local cobj = assert(font.ptr)

	return {
		title = mattext.block(cobj, fontid, 28, 0xfff4f7ff, "CV"),
		number = mattext.block(cobj, fontid, 72, 0xffffd166, "CV"),
	}
end)

local title = computed(function()
	return blocks().title("Reactive Counter", w, 48)
end)

local number = computed(function()
	return blocks().number(tostring(count()), w, 96)
end)

local card <const> = matquad.quad(w, h, 0xff202636)
local card_border <const> = matquad.quad(w + 4, h + 4, 0xff4f7cff)

view.mount("button", {
	x = minus_rect.x,
	y = minus_rect.y,
	w = minus_rect.w,
	h = minus_rect.h,
	label = "-",
	color = 0xff374151,
	hover_color = 0xff4b5563,
	text_size = BUTTON_TEXT_SIZE,
	on_click = function()
		count(count() - 1)
	end,
})

view.mount("button", {
	x = plus_rect.x,
	y = plus_rect.y,
	w = plus_rect.w,
	h = plus_rect.h,
	label = "+",
	color = 0xff4f7cff,
	hover_color = 0xff6b91ff,
	text_size = BUTTON_TEXT_SIZE,
	on_click = function()
		count(count() + 1)
	end,
})

return function(batch)
	batch:add(card_border, -2, -2)
	batch:add(card, 0, 0)
	batch:add(title(), 0, 24)
	batch:add(number(), 0, 78)
end
