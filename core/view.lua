local font = require "core.font"
local sfont = require "soluna.font"
---@class SolunaFile
---@field searchpath fun(name: string, path: string): string?
---@field load fun(path: string): string?
---@type SolunaFile
---@diagnostic disable-next-line: assign-type-mismatch
local file = require "soluna.file"

local COMPONENT_PATH <const> = "?.lua;?/init.lua"

---@class ViewCommand
---@field name string
---@field args table

---@class ViewLayout
---@field x number?
---@field y number?
---@field w number?
---@field h number?

---@class ViewBatch
---@field layer fun(self: ViewBatch, x?: number, y?: number)

---@class (partial) ViewEffect
---@field scope ViewScope
---@field fn fun()
---@field deps table[]
---@field queued boolean?
---@field stopped boolean?

---@class (partial) ViewScope
---@field targets table
---@field active ViewEffect?
---@field queue table<integer, ViewEffect?>
---@field queue_head integer
---@field queue_tail integer

---@class (partial) ViewValue<T>
---@overload fun(): T
---@overload fun(value: T)
---@field scope ViewScope
---@field value T

---@alias ViewComputed<T> fun(): T

---@class (partial) ViewComputedState<T>
---@field effect ViewEffect?
---@field value ViewValue<T>

---@class (partial) ViewInstance
---@field view View
---@field parent ViewInstance?
---@field children ViewInstance[]
---@field layout ViewLayout
---@field disposables ViewComputedState<any>[]?
---@field mounted boolean?
---@field effect ViewEffect?
---@field commands ViewCommand[]?
---@field pointer fun(x: number, y: number)?
---@field click fun(x: number, y: number): any?

---@class (partial) View
---@field scope ViewScope
---@field instances ViewInstance[]
---@field w number
---@field h number
---@field pointer_x number?
---@field pointer_y number?
---@field resources table

---@class ViewContext
---@field view View
---@field instance ViewInstance?
---@field disposables ViewComputedState<any>[]?
---@field mounting boolean?
---@field drawing boolean?

---@type ViewContext?
local active

---@class (partial) ViewScope
local Scope = {}; do
	---@param effect ViewEffect
	local function cleanup(effect)
		for i = 1, #effect.deps do
			effect.deps[i][effect] = nil
			effect.deps[i] = nil
		end
	end

	Scope.__index = Scope

	---@class (partial) ViewEffect
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

	---@class (partial) ViewValue<T>
	local Value = {}; do
		---@generic T
		---@param self ViewValue<T>
		---@return T
		local function read(self)
			local scope = rawget(self, "scope")
			scope:track(self, "value")
			return rawget(self, "value")
		end

		---@generic T
		---@param self ViewValue<T>
		---@param value T
		local function write(self, value)
			local old = rawget(self, "value")
			if old == value then
				return
			end
			rawset(self, "value", value)
			rawget(self, "scope"):trigger(self, "value")
		end

		---@generic T
		---@return T?
		function Value:__call(...args)
			if args.n == 0 then
				return read(self)
			end
			write(self, table.unpack(args, 1, args.n))
		end

		---@generic T
		---@param key string
		---@return any
		function Value:__index(key)
			if key == "value" then
				return read(self)
			end
			return Value[key]
		end

		---@param key string
		---@param value any
		function Value:__newindex(key, value)
			if key == "value" then
				write(self, value)
				return
			end
			rawset(self, key, value)
		end
	end

	---@param target table
	---@param key string
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

	---@param effect ViewEffect
	function Scope:schedule(effect)
		if effect.stopped or effect.queued then
			return
		end
		effect.queued = true
		local tail = self.queue_tail + 1
		self.queue_tail = tail
		self.queue[tail] = effect
	end

	---@param target table
	---@param key string
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

	---@param effect ViewEffect
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

	---@generic T
	---@param value T
	---@return ViewValue<T>
	function Scope:value(value)
		return setmetatable({
			scope = self,
			value = value,
		}, Value)
	end

	---@param fn fun()
	---@return ViewEffect
	function Scope:effect(fn)
		---@type ViewEffect
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

---@class (partial) View
local View = {}; do
	View.__index = View


	---@class (partial) ViewInstance
	local Instance = {}; do
		Instance.__index = Instance

		---@return number, number
		function Instance:container_size()
			local parent = self.parent
			if parent then
				return parent.layout.w or self.view.w, parent.layout.h or self.view.h
			end
			return self.view.w, self.view.h
		end

		---@return number, number
		function Instance:origin()
			local layout = self.layout
			local x = layout.x
			local y = layout.y
			local w = layout.w
			local h = layout.h
			local parent_w, parent_h = self:container_size()

			if x == nil and w ~= nil then
				x = (parent_w - w) / 2
			end
			if y == nil and h ~= nil then
				y = (parent_h - h) / 2
			end

			return x or 0, y or 0
		end

		---@param x number
		---@param y number
		---@return number, number
		function Instance:local_point(x, y)
			local ox, oy = self:origin()
			return x - ox, y - oy
		end

		---@param x number
		---@param y number
		---@return boolean
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

		---@param batch ViewBatch
		function Instance:draw(batch)
			if not self.commands then
				return
			end
			for i = 1, #self.commands do
				local command = self.commands[i]
				---@type fun(batch: ViewBatch, ...: any)
				---@diagnostic disable-next-line: undefined-field
				local f = assert(batch[command.name])
				local args = command.args
				f(batch, table.unpack(args, 1, args.n))
			end
		end

		function Instance:destroy()
			if not self.mounted then return end
			self.mounted = nil
			for i = #self.children, 1, -1 do
				self.children[i]:destroy()
				self.children[i] = nil
			end
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

	---@param view View
	---@param parent ViewInstance?
	---@param instance ViewInstance
	local function append_child(view, parent, instance)
		if parent then
			parent.children[#parent.children + 1] = instance
		else
			view.instances[#view.instances + 1] = instance
		end
	end

	---@param batch ViewBatch
	---@param instance ViewInstance
	local function draw_node(batch, instance)
		if not instance.mounted then
			return
		end
		local x, y = instance:origin()
		batch:layer(x, y)
		instance:draw(batch)
		for i = 1, #instance.children do
			draw_node(batch, instance.children[i])
		end
		batch:layer()
	end

	---@param instance ViewInstance
	---@param x number
	---@param y number
	local function pointer_node(instance, x, y)
		if not instance.mounted then
			return
		end
		local lx, ly = instance:local_point(x, y)
		if instance.pointer then
			instance.pointer(lx, ly)
		end
		for i = 1, #instance.children do
			pointer_node(instance.children[i], lx, ly)
		end
	end

	---@param instance ViewInstance
	---@param x number
	---@param y number
	---@return ViewInstance?
	local function click_node(instance, x, y)
		if not instance.mounted or not instance:contains(x, y) then
			return nil
		end
		local lx, ly = instance:local_point(x, y)
		for i = #instance.children, 1, -1 do
			local target = click_node(instance.children[i], lx, ly)
			if target then
				return target
			end
		end
		if instance.click and instance.click(lx, ly) ~= false then
			return instance
		end
		return nil
	end

	local Recorder = {}; do
		local methods = {}
		---@param name string
		function Recorder.__index(_, name)
			local method = methods[name] or function(self, ...args)
				local commands = self.commands
				commands[#commands + 1] = {
					name = name,
					args = args,
				}
			end
			methods[name] = method
			return method
		end
	end

	---@param props table?
	---@return ViewLayout
	local function layout(props)
		props = props or {}
		return {
			x = props.x,
			y = props.y,
			w = props.w,
			h = props.h,
		}
	end

	---@param chunk string
	---@param props table?
	---@param parent ViewInstance?
	---@return ViewInstance
	function View:mount(chunk, props, parent)
		local path = assert(file.searchpath(chunk, self.resources.component_path))
		local source = assert(file.load(path))
		---@diagnostic disable-next-line: assign-type-mismatch
		chunk = assert(load(source, "@" .. path, "t"))
		assert(type(chunk) == "function")

		---@type ViewInstance
		local instance = setmetatable({
			view = self,
			parent = parent,
			children = {},
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
		---@type ViewContext
		active = {
			view = self,
			instance = instance,
			disposables = instance.disposables,
			mounting = true,
		}
		local result = table.pack(pcall(chunk, args))
		---@cast result table<integer, any>
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

		local target, ctx

		instance.effect = self.scope:effect(function()
			if not instance.mounted then
				return
			end
			target = target or setmetatable({
				commands = {},
			}, Recorder)
			---@diagnostic disable-next-line: redefined-local
			local prev = active
			---@type ViewContext
			ctx = ctx or {
				view = self,
				instance = instance,
				drawing = true,
			}
			active = ctx
			for i = 1, #target.commands do
				target.commands[i] = nil
			end
			local ok, err = pcall(draw, target)
			active = prev
			if not ok then
				error(err, 0)
			end
			instance.commands = target.commands
		end)

		append_child(self, parent, instance)
		return instance
	end

	function View:update()
		return self.scope:flush()
	end

	---@param w number
	---@param h number
	function View:resize(w, h)
		self.w = w
		self.h = h
		if self.pointer_x ~= nil and self.pointer_y ~= nil then
			self:pointer(self.pointer_x, self.pointer_y)
		end
	end

	---@param x number
	---@param y number
	function View:pointer(x, y)
		self.pointer_x = x
		self.pointer_y = y
		for i = 1, #self.instances do
			local instance = self.instances[i]
			pointer_node(instance, x, y)
		end
	end

	---@param x number?
	---@param y number?
	---@return ViewInstance?
	function View:click(x, y)
		x = x or self.pointer_x
		y = y or self.pointer_y
		if x == nil or y == nil then
			return
		end
		for i = #self.instances, 1, -1 do
			local target = click_node(self.instances[i], x, y)
			if target then
				return target
			end
		end
	end

	---@param batch ViewBatch
	function View:draw(batch)
		for i = 1, #self.instances do
			draw_node(batch, self.instances[i])
		end
	end

	---@param name string
	---@param resource any
	function View:set_resource(name, resource)
		self.resources[name] = resource
		self.scope:trigger(self.resources, name)
	end
end

local M = {}

---@param args table?
---@return View
function M.new(args)
	args = args or {}
	---@type View
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

---@class (partial) ViewComputedState<T>
local Computed = {}; do
	Computed.__index = Computed

	---@generic T
	---@return T
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

---@generic T
---@param value T
---@return ViewValue<T>
function M.value(value)
	---@cast active ViewContext
	return active.view.scope:value(value)
end

---@param name string
---@return any
function M.resource(name)
	---@cast active ViewContext
	local view = active.view
	view.scope:track(view.resources, name)
	return assert(view.resources[name])
end

---@param chunk string
---@param props table?
---@return ViewInstance
function M.mount(chunk, props)
	local current = assert(active, "view.mount requires an active component context")
	if current.drawing then
		error("view.mount cannot be called while drawing", 2)
	end
	assert(current.mounting and current.instance, "view.mount can only be called while mounting a component")
	return current.view:mount(chunk, props, current.instance)
end

---@generic T
---@param fn fun(): T, ...
---@return ViewComputed<T>
function M.computed(fn)
	---@cast active ViewContext
	assert(active.disposables)
	local view = active.view
	---@type ViewValue<T>
	local value = view.scope:value(nil)
	---@type ViewContext
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
	---@type ViewComputedState<T>
	local computed = setmetatable({
		effect = effect,
		value = value,
	}, Computed)
	active.disposables[#active.disposables + 1] = computed
	---@cast computed ViewComputed<T>
	return computed
end

return M
