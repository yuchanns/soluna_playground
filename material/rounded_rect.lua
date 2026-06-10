local render = require "soluna.render"
local rounded_rect = require "playground.material.rounded_rect"

local ctx = ...
local state = ctx.state
local render_conf = ctx.settings

rounded_rect.set_material_id(ctx.id)

local inst_buffer = render.buffer {
	type = "vertex",
	usage = "stream",
	label = "playground-rounded-rect-instance",
	size = rounded_rect.instance_size * render_conf.draw_instance,
}

local bindings = render.bindings()
bindings:vbuffer(0, inst_buffer)

local cobj = rounded_rect.new {
	inst_buffer = inst_buffer,
	bindings = bindings,
	uniform = state.uniform,
	tmp_buffer = ctx.tmp_buffer,
}

local material = {}

function material.reset()
	cobj:reset()
end

function material.submit(ptr, n)
	cobj:submit(ptr, n)
end

function material.draw(ptr, n)
	cobj:draw(ptr, n)
end

return material
