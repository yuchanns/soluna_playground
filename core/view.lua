local font = require "core.font"
local sfont = require "soluna.font"
local file = require "soluna.file"

local COMPONENT_PATH <const> = "?.lua;?/init.lua"

local Scope = {}; do
	local function cleanup(effect)
		for i = 1, #effect.deps do
			effect.deps[i][effect] = nil
			effect.deps[i] = nil
		end
	end

	Scope.__index = Scope

	local Effect = {}; do
		Effect.__index = Effect
		function Effect:stop()
			if self.stopped then
				return
			end
			self.stopped = true
			self.queued = nil
			cleanup(self)
		end
	end

	local Value = {}; do
		local function read(self)
			local scope = rawget(self, "scope")
			scope:track(self, "value")
			return rawget(self, "value")
		end

		local function write(self, value)
			local old = rawget(self, "value")
			if old == value then
				return
			end
			rawset(self, "value", value)
			rawget(self, "scope"):trigger(self, "value")
		end

		function Value:__call(...args)
			if args.n == 0 then
				return read(self)
			end
			write(self, table.unpack(args, 1, args.n))
		end

		function Value:__index(key)
			if key == "value" then
				return read(self)
			end
			return Value[key]
		end

		function Value:__newindex(key, value)
			if key == "value" then
				write(self, value)
				return
			end
			rawset(self, key, value)
		end
	end

	function Scope:track(target, key)
		local effect = self.active
		if not effect or effect.stopped then
			return
		end

		local deps = self.targets[target] or {}
		self.targets[target] = deps

		local dep = deps[key] or {}
		deps[key] = dep

		if dep[effect] then
			return
		end

		dep[effect] = true
		effect.deps[#effect.deps + 1] = dep
	end

	function Scope:schedule(effect)
		if effect.stopped or effect.queued then
			return
		end
		effect.queued = true
		local tail = self.queue_tail + 1
		self.queue_tail = tail
		self.queue[tail] = effect
	end

	function Scope:trigger(target, key)
		local deps = self.targets[target]
		if not deps then
			return
		end

		local dep = deps[key]
		if not dep then
			return
		end

		for effect in pairs(dep) do
			self:schedule(effect)
		end
	end

	function Scope:run(effect)
		if effect.stopped then
			return
		end
		cleanup(effect)
		local prev = self.active
		self.active = effect
		local ok, err = pcall(effect.fn)
		self.active = prev
		if not ok then
			error(err, 0)
		end
	end

	function Scope:value(value)
		return setmetatable({
			scope = self,
			value = value,
		}, Value)
	end

	function Scope:effect(fn)
		local effect = setmetatable({
			scope = self,
			fn = fn,
			deps = {},
		}, Effect)
		self:run(effect)
		return effect
	end

	function Scope:flush()
		while self.queue_head <= self.queue_tail do
			local head = self.queue_head
			local effect = self.queue[head]
			self.queue[head] = nil
			self.queue_head = head + 1
			if effect and not effect.stopped then
				effect.queued = nil
				self:run(effect)
			end
		end
		self.queue_head = 1
		self.queue_tail = 0
	end
end

local active

local View = {}; do
	View.__index = View


	local Instance = {}; do
		Instance.__index = Instance

		function Instance:origin()
			local layout = self.layout
			local x = layout.x
			local y = layout.y
			local w = layout.w
			local h = layout.h
			local view = self.view

			if x == nil and w ~= nil then
				x = (view.w - w) / 2
			end
			if y == nil and h ~= nil then
				y = (view.h - h) / 2
			end

			return x or 0, y or 0
		end

		function Instance:local_point(x, y)
			local ox, oy = self:origin()
			return x - ox, y - oy
		end

		function Instance:contains(x, y)
			local layout = self.layout
			local w = layout.w
			local h = layout.h
			if w == nil or h == nil then
				return true
			end
			local lx, ly = self:local_point(x, y)
			return lx >= 0 and lx <= w and ly >= 0 and ly <= h
		end

		function Instance:draw(batch)
			if not self.commands then
				return
			end
			for i = 1, #self.commands do
				local command = self.commands[i]
				local f = assert(batch[command.name])
				local args = command.args
				f(batch, table.unpack(args, 1, args.n))
			end
		end

		function Instance:destroy()
			if not self.mounted then return end
			self.mounted = nil
			if self.effect then
				self.effect:stop()
				self.effect = nil
			end
			if self.disposables then
				for i = #self.disposables, 1, -1 do
					self.disposables[i]:stop()
					self.disposables[i] = nil
				end
				self.disposables = nil
			end
			self.commands = nil
		end
	end

	local Recorder = {}; do
		function Recorder.__index(_, name)
			return function(self, ...args)
				local commands = self.commands
				commands[#commands + 1] = {
					name = name,
					args = args,
				}
			end
		end
	end

	local function layout(props)
		props = props or {}
		return {
			x = props.x,
			y = props.y,
			w = props.w,
			h = props.h,
		}
	end

	function View:mount(chunk, props)
		local path = assert(file.searchpath(chunk, self.resources.component_path))
		local source = assert(file.load(path))
		chunk = assert(load(source, "@" .. path, "t"))
		assert(type(chunk) == "function")

		local instance = setmetatable({
			view = self,
			layout = layout(props),
			disposables = {},
			mounted = true,
		}, Instance)
		local exports = {}
		local args = {}; if props then
			for key, value in pairs(props) do
				args[key] = value
			end
		end
		args.dispatch = function() return exports end

		local prev = active
		active = { view = self, disposables = instance.disposables }
		local result = table.pack(pcall(chunk, args))
		active = prev
		if not result[1] then
			error(result[2], 0)
		end
		local draw = result[2]
		assert(type(draw) == "function")
		for key, value in pairs(exports) do
			assert(not instance[key])
			instance[key] = value
		end

		instance.effect = self.scope:effect(function()
			if not instance.mounted then
				return
			end
			local target = setmetatable({
				commands = {},
			}, Recorder)
			local prev = active
			active = { view = self }
			local ok, err = pcall(draw, target)
			active = prev
			if not ok then
				error(err, 0)
			end
			instance.commands = target.commands
		end)

		self.instances[#self.instances + 1] = instance
		return instance
	end

	function View:update()
		return self.scope:flush()
	end

	function View:resize(w, h)
		self.w = w
		self.h = h
		if self.pointer_x ~= nil and self.pointer_y ~= nil then
			self:pointer(self.pointer_x, self.pointer_y)
		end
	end

	function View:pointer(x, y)
		self.pointer_x = x
		self.pointer_y = y
		for i = 1, #self.instances do
			local instance = self.instances[i]
			if instance.mounted and instance.pointer then
				instance.pointer(instance:local_point(x, y))
			end
		end
	end

	function View:click(x, y)
		x = x or self.pointer_x
		y = y or self.pointer_y
		if x == nil or y == nil then
			return
		end
		for i = #self.instances, 1, -1 do
			local instance = self.instances[i]
			if instance.mounted and instance.click and instance:contains(x, y) then
				instance.click(instance:local_point(x, y))
				return instance
			end
		end
	end

	function View:draw(batch)
		for i = 1, #self.instances do
			local instance = self.instances[i]
			if instance.mounted then
				local x, y = instance:origin()
				batch:layer(x, y)
				instance:draw(batch)
				batch:layer()
			end
		end
	end

	function View:set_resource(name, resource)
		self.resources[name] = resource
		self.scope:trigger(self.resources, name)
	end
end

local M = {}

function M.new(args)
	args = args or {}
	return setmetatable({
		scope = setmetatable({
			targets = setmetatable({}, {
				__mode = "k",
			}),
			queue = {},
			queue_head = 1,
			queue_tail = 0,
		}, Scope),
		instances = {},
		w = args.w or args.width or 0,
		h = args.h or args.height or 0,
		pointer_x = nil,
		pointer_y = nil,
		resources = {
			font = {
				loaded = font.load(),
				ptr = sfont.cobj(),
			},
			component_path = args.component_path or COMPONENT_PATH
		},
	}, View)
end

local Computed = {}; do
	Computed.__index = Computed

	function Computed:__call()
		return self.value()
	end

	function Computed:stop()
		if not self.effect then
			return
		end
		self.effect:stop()
		self.effect = nil
	end
end

function M.value(value)
	return active.view.scope:value(value)
end

function M.resource(name)
	local view = active.view
	view.scope:track(view.resources, name)
	return assert(view.resources[name])
end

function M.computed(fn)
	assert(active.disposables)
	local view = active.view
	local value = view.scope:value(nil)
	local ctx = {
		view = view,
	}
	local effect = view.scope:effect(function()
		local prev = active
		active = ctx
		local ok, result = pcall(fn)
		active = prev
		if not ok then
			error(result, 0)
		end
		value(result)
	end)
	local computed = setmetatable({
		effect = effect,
		value = value,
	}, Computed)
	active.disposables[#active.disposables + 1] = computed
	return computed
end

return M
