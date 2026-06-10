local view = require "core.view"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"
local floor = math.floor

local args = ...
local C = args.dispatch()

local hover = view.value(false)
local active = view.value(false)

function C.pointer(x, y)
	local width = args.width
	local height = args.height
	hover(x >= 0 and x <= width and y >= 0 and y <= height)
end

function C.click()
	active(not active())
end

return function()
	view.canvas({
		width = args.width,
		height = args.height,
	}, function(width, height)
		local canvas_w = math.max(floor(width + 0.5), 1)
		local canvas_h = math.max(floor(height + 0.5), 1)
		local is_hover = hover()
		local is_active = active()
		local background = is_active and 0xff1f8f5f or 0xff2f4f7f
		local foreground = is_hover and 0xff75a7ff or 0xffe2e8ff
		local inset_w = math.max(canvas_w - 32, 1)
		local inset_h = math.max(canvas_h - 32, 1)
		local title = is_active and "Canvas: active" or "Canvas: idle"

		local font_resource = view.resource "font"
		local fontid = assert(font_resource.loaded).id
		local cobj = assert(font_resource.ptr)
		local block = mattext.block(cobj, fontid, 24, 0xffffffff, "CV")

		view.batch:add(matquad.quad(canvas_w, canvas_h, background), 0, 0)
		view.batch:add(matquad.quad(inset_w, inset_h, foreground), 16, 16)
		view.batch:add(block(title, canvas_w, canvas_h), 0, 0)
	end)
end
