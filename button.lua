local view = require "core.view"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"

local value = view.value
local computed = view.computed
local args = ...
local C = args.dispatch()

local w <const> = assert(args.w)
local h <const> = assert(args.h)
local label <const> = assert(args.label)
local color <const> = args.color or 0xff4f7cff
local hover_color <const> = args.hover_color or color
local text_color <const> = args.text_color or 0xffffffff
local text_size <const> = args.text_size or 18
local on_click <const> = args.on_click

local hover = value(false)

local block = computed(function()
	local font = view.resource "font"
	local fontid = assert(font.loaded).id
	local cobj = assert(font.ptr)

	return mattext.block(cobj, fontid, text_size, text_color, "CV")
end)

local text = computed(function()
	return block()(label, w, h)
end)

local normal_quad <const> = matquad.quad(w, h, color)
local hover_quad <const> = matquad.quad(w, h, hover_color)

local function inside(x, y)
	return x ~= nil and y ~= nil and x >= 0 and x <= w and y >= 0 and y <= h
end

function C.pointer(x, y)
	hover(inside(x, y))
end

function C.click(x, y)
	if inside(x, y) and on_click then
		on_click()
	end
end

return function(batch)
	batch:add(hover() and hover_quad or normal_quad, 0, 0)
	batch:add(text(), 0, 0)
end
