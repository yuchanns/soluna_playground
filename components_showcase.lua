local view = require "core.view"

local args = ...

local PAGE_BG <const> = 0xfff3f4f6
local CARD_BG <const> = 0xffffffff
local TEXT <const> = 0xff111827
local MUTED <const> = 0xff6b7280
local LINE <const> = 0xffe5e7eb
local PRIMARY <const> = 0xff2563eb
local PRIMARY_HOVER <const> = 0xff1d4ed8
local PRIMARY_PRESSED <const> = 0xff1e40af

local nav_items <const> = {
	{
		id = "overview",
		icon = "circle",
		label = "Overview",
	},
	{
		id = "settings",
		icon = "wrench",
		label = "Settings",
	},
	{
		id = "activity",
		icon = "clock",
		label = "Activity",
	},
}

local select_options <const> = {
	{
		value = "small",
		label = "Small",
	},
	{
		value = "medium",
		label = "Medium",
	},
	{
		value = "large",
		label = "Large",
	},
}

local selected_nav = view.value "settings"
local selected_size = view.value "medium"
local select_open = view.value(false)
local enabled_toggle = view.value(true)
local disabled_toggle = view.value(false)
local button_clicks = view.value(0)

view.clickable {
	on_click = function()
		select_open(false)
	end,
}

local function card(title, subtitle, layout, children)
	local style = {
	}
	for key, value in pairs(layout) do
		style[key] = value
	end

	view.box(style, function()
		view.mount("view/surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = CARD_BG,
			radius = 10,
		})
		view.vbox({
			width = "100%",
			height = "100%",
			padding = 18,
			gap = 12,
		}, function()
			view.text(title, {
				width = "100%",
				height = 26,
				size = 20,
				color = TEXT,
				align = "LV",
			})
			view.text(subtitle, {
				width = "100%",
				height = 22,
				size = 14,
				color = MUTED,
				align = "LV",
			})
			view.box {
				width = "100%",
				height = 1,
				background = LINE,
			}
			children()
		end)
	end)
end

return function()
	local width = assert(args.width)
	local height = assert(args.height)
	local active_nav = selected_nav()
	local size_value = selected_size()
	local open = select_open()
	local toggle_value = enabled_toggle()
	local disabled_value = disabled_toggle()

	view.vbox({
		width = width,
		height = height,
		background = PAGE_BG,
		padding = 32,
		gap = 24,
	}, function()
		view.text("Component Showcase", {
			width = "100%",
			height = 38,
			size = 30,
			color = TEXT,
			align = "LV",
		})
		view.text("Examples for the reactive view runtime.", {
			width = "100%",
			height = 24,
			size = 16,
			color = MUTED,
			align = "LV",
		})

		view.hbox({
			width = "100%",
			height = 270,
			gap = 24,
		}, function()
			card("Buttons", "Default, primary, icon and disabled states.", {
				width = 340,
				height = "100%",
			}, function()
				view.hbox({
					width = "100%",
					height = 42,
					gap = 12,
					alignItems = "center",
				}, function()
					view.mount("view/button", {
						label = "Default",
						width = 112,
						height = 36,
						on_click = function()
							button_clicks(button_clicks() + 1)
						end,
					})
					view.mount("view/button", {
						label = "Primary",
						width = 112,
						height = 36,
						background = PRIMARY,
						hover_background = PRIMARY_HOVER,
						pressed_background = PRIMARY_PRESSED,
						text_color = 0xffffffff,
						on_click = function()
							button_clicks(button_clicks() + 1)
						end,
					})
				end)
				view.hbox({
					width = "100%",
					height = 42,
					gap = 12,
					alignItems = "center",
				}, function()
					view.mount("view/icon_button", {
						name = "pencil",
						width = 36,
						height = 36,
						on_click = function()
							button_clicks(button_clicks() + 1)
						end,
					})
					view.mount("view/icon_button", {
						name = "close",
						width = 36,
						height = 36,
						enabled = false,
					})
					view.mount("view/button", {
						label = "Disabled",
						width = 112,
						height = 36,
						enabled = false,
					})
				end)
				view.text("Clicks: " .. tostring(button_clicks()), {
					width = "100%",
					height = 24,
					size = 14,
					color = MUTED,
					align = "LV",
				})
			end)

			card("Navigation", "Controlled selected item with hover feedback.", {
				width = 340,
				height = "100%",
			}, function()
				view.box({
					width = 236,
					height = 136,
				}, function()
					view.mount("view/surface", {
						position = "absolute",
						left = 0,
						top = 0,
						width = "100%",
						height = "100%",
						fill = 0xfff9fafb,
						radius = 8,
					})
					view.vbox({
						width = 236,
						height = 136,
						padding = 8,
						gap = 4,
					}, function()
						for i = 1, #nav_items do
							local item = nav_items[i]
							view.mount("view/nav_item", {
								key = item.id,
								id = item.id,
								icon = item.icon,
								label = item.label,
								width = "100%",
								height = 36,
								active = item.id == active_nav,
								on_select = function(id)
									selected_nav(id)
								end,
							})
						end
					end)
				end)
				view.text("Selected: " .. active_nav, {
					width = "100%",
					height = 24,
					size = 14,
					color = MUTED,
					align = "LV",
				})
			end)

			card("Toggle", "Boolean switch with enabled and disabled examples.", {
				flex = 1,
				height = "100%",
			}, function()
				view.hbox({
					width = "100%",
					height = 38,
					gap = 14,
					alignItems = "center",
				}, function()
					view.text("Enabled", {
						width = 120,
						height = "100%",
						size = 15,
						color = TEXT,
						align = "LV",
					})
					view.mount("view/toggle", {
						width = 54,
						height = 28,
						checked = toggle_value,
						on_change = function(next_value)
							enabled_toggle(next_value)
						end,
					})
					view.text(tostring(toggle_value), {
						width = 80,
						height = "100%",
						size = 14,
						color = MUTED,
						align = "LV",
					})
				end)
				view.hbox({
					width = "100%",
					height = 38,
					gap = 14,
					alignItems = "center",
				}, function()
					view.text("Disabled", {
						width = 120,
						height = "100%",
						size = 15,
						color = TEXT,
						align = "LV",
					})
					view.mount("view/toggle", {
						width = 54,
						height = 28,
						checked = disabled_value,
						enabled = false,
					})
					view.text(tostring(disabled_value), {
						width = 80,
						height = "100%",
						size = 14,
						color = MUTED,
						align = "LV",
					})
				end)
			end)
		end)

		view.hbox({
			width = "100%",
			height = 250,
			gap = 24,
		}, function()
			card("Select", "Menu is an overlay and does not change card height.", {
				width = 420,
				height = "100%",
			}, function()
				view.mount("view/select", {
					width = 280,
					height = 36,
					value = size_value,
					open = open,
					options = select_options,
					on_open_change = function(next_open)
						select_open(next_open)
					end,
					on_change = function(next_value)
						selected_size(next_value)
						select_open(false)
					end,
				})
				view.box {
					width = "100%",
					height = 112,
				}
				view.text("Selected: " .. size_value, {
					width = "100%",
					height = 24,
					size = 14,
					color = MUTED,
					align = "LV",
				})
			end)

			card("Composition", "Owner state flows down as snapshot props.", {
				flex = 1,
				height = "100%",
			}, function()
				view.text("Children report interaction through callbacks.", {
					width = "100%",
					height = 24,
					size = 15,
					color = TEXT,
					align = "LV",
				})
				view.text("The owner rerenders children with ordinary prop values.", {
					width = "100%",
					height = 24,
					size = 15,
					color = TEXT,
					align = "LV",
				})
				view.text("Click empty page space to close the select menu.", {
					width = "100%",
					height = 24,
					size = 14,
					color = MUTED,
					align = "LV",
				})
			end)
		end)
	end)
end
