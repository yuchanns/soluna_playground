local view = require "core.view"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"

local BUTTON_W <const> = 96
local BUTTON_H <const> = 48
local BUTTON_GAP <const> = 40

local value = view.value
local computed = view.computed
local args = ...
local C = args.dispatch()

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
local hover = value(0)

local blocks = computed(function()
	local font = view.resource "font"
	local fontid = assert(font.loaded).id
	local cobj = assert(font.ptr)

	return {
		title = mattext.block(cobj, fontid, 28, 0xfff4f7ff, "CV"),
		number = mattext.block(cobj, fontid, 72, 0xffffd166, "CV"),
		button = mattext.block(cobj, fontid, 18, 0xffffffff, "CV"),
	}
end)

local title = computed(function()
	return blocks().title("Reactive Counter", w, 48)
end)

local number = computed(function()
	return blocks().number(tostring(count()), w, 96)
end)

local function hit(x, y)
	if x == nil or y == nil then
		return 0
	end

	local function inside(rect, x, y)
		return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
	end

	if inside(minus_rect, x, y) then
		return -1
	end

	if inside(plus_rect, x, y) then
		return 1
	end

	return 0
end

function C.pointer(x, y)
	hover(hit(x, y))
end

function C.click(x, y)
	local delta = hit(x, y)
	count(count() + delta)
end

local minus = computed(function()
	return blocks().button("-", minus_rect.w, minus_rect.h)
end)

local plus = computed(function()
	return blocks().button("+", plus_rect.w, plus_rect.h)
end)

local card <const> = matquad.quad(w, h, 0xff202636)
local card_border <const> = matquad.quad(w + 4, h + 4, 0xff4f7cff)
local button <const> = matquad.quad(BUTTON_W, BUTTON_H, 0xff4f7cff)
local button_hover <const> = matquad.quad(BUTTON_W, BUTTON_H, 0xff6b91ff)
local button_secondary <const> = matquad.quad(BUTTON_W, BUTTON_H, 0xff374151)
local button_secondary_hover <const> = matquad.quad(BUTTON_W, BUTTON_H, 0xff4b5563)


return function(batch)
	local current = hover()
	local plus_hover = current == 1
	local minus_hover = current == -1

	batch:add(card_border, -2, -2)
	batch:add(card, 0, 0)
	batch:add(title(), 0, 24)
	batch:add(number(), 0, 78)
	batch:add(minus_hover and button_secondary_hover or button_secondary, minus_rect.x, minus_rect.y)
	batch:add(minus(), minus_rect.x, minus_rect.y)
	batch:add(plus_hover and button_hover or button, plus_rect.x, plus_rect.y)
	batch:add(plus(), plus_rect.x, plus_rect.y)
end
