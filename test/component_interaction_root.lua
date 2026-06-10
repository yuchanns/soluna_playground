local view = require "core.view"

local args = ...
local events <const> = assert(args.events)

local selected_nav = view.value "overview"
local selected_size = view.value "small"
local select_open = view.value(false)
local toggle_checked = view.value(false)

local options <const> = {
	{
		value = "small",
		label = "Small",
	},
	{
		value = "medium",
		label = "Medium",
	},
}

return function()
	local nav = selected_nav()
	local size = selected_size()
	local open = select_open()
	local checked = toggle_checked()

	view.vbox({
		width = args.width,
		height = args.height,
		padding = 20,
		gap = 12,
	}, function()
		view.mount("view/button", {
			label = "Action",
			width = 100,
			height = 36,
			on_click = function()
				events.button = events.button + 1
			end,
		})
		view.mount("view/nav_item", {
			id = "settings",
			label = "Settings",
			icon = "wrench",
			width = 160,
			height = 36,
			active = nav == "settings",
			on_select = function(id)
				events.nav = id
				selected_nav(id)
			end,
		})
		view.mount("view/toggle", {
			width = 54,
			height = 28,
			checked = checked,
			on_change = function(next_value)
				events.toggle = next_value
				toggle_checked(next_value)
			end,
		})
		view.mount("view/select", {
			width = 180,
			height = 36,
			value = size,
			open = open,
			options = options,
			on_open_change = function(next_open)
				events.open = next_open
				select_open(next_open)
			end,
			on_change = function(next_value)
				events.select = next_value
				selected_size(next_value)
				select_open(false)
			end,
		})
	end)
end
