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
local PAGE_PADDING <const> = 32
local CONTENT_WIDTH <const> = 1136
local GAP <const> = 24
local THREE_COLUMN_MIN_WIDTH <const> = 816
local WIDE_TOP_ROW_WIDTH <const> = 1068
local BOTTOM_ROW_MIN_WIDTH <const> = 760

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

---@param width number
---@param button_width number
local function render_buttons_card(width, button_width)
	card("Buttons", "Default, primary, icon and disabled states.", {
		width = width,
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
				width = button_width,
				height = 36,
				on_click = function()
					button_clicks(button_clicks() + 1)
				end,
			})
			view.mount("view/button", {
				label = "Primary",
				width = button_width,
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
				width = button_width,
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
end

---@param width number
---@param nav_width number
---@param active_nav string
local function render_navigation_card(width, nav_width, active_nav)
	card("Navigation", "Controlled selected item with hover feedback.", {
		width = width,
		height = "100%",
	}, function()
		view.vbox({
			width = nav_width,
			height = 172,
			gap = 8,
		}, function()
			view.box({
				width = nav_width,
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
					width = nav_width,
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
			view.box({
				width = "100%",
				height = 24,
				paddingLeft = 8,
			}, function()
				view.text("Selected: " .. active_nav, {
					width = "100%",
					height = "100%",
					size = 14,
					color = MUTED,
					align = "LV",
				})
			end)
		end)
	end)
end

---@param layout table
---@param label_width number
---@param value_width number
---@param row_gap number
---@param toggle_value boolean
---@param disabled_value boolean
---@param refs table?
local function render_toggle_card(layout, label_width, value_width, row_gap, toggle_value, disabled_value, refs)
	card("Toggle", "Boolean switch with enabled and disabled examples.", layout, function()
		view.hbox({
			width = "100%",
			height = 38,
			gap = row_gap,
			alignItems = "center",
		}, function()
			view.text("Enabled", {
				width = label_width,
				height = "100%",
				size = 15,
				color = TEXT,
				align = "LV",
			})
			view.mount("view/toggle", {
				ref = refs and refs.enabled_toggle,
				width = 54,
				height = 28,
				checked = toggle_value,
				on_change = function(next_value)
					enabled_toggle(next_value)
				end,
			})
			view.text(tostring(toggle_value), {
				width = value_width,
				height = "100%",
				size = 14,
				color = MUTED,
				align = "LV",
			})
		end)
		view.hbox({
			width = "100%",
			height = 38,
			gap = row_gap,
			alignItems = "center",
		}, function()
			view.text("Disabled", {
				width = label_width,
				height = "100%",
				size = 15,
				color = TEXT,
				align = "LV",
			})
			view.mount("view/toggle", {
				ref = refs and refs.disabled_toggle,
				width = 54,
				height = 28,
				checked = disabled_value,
				enabled = false,
			})
			view.text(tostring(disabled_value), {
				width = value_width,
				height = "100%",
				size = 14,
				color = MUTED,
				align = "LV",
			})
		end)
	end)
end

---@param content_width number
---@param active_nav string
---@param toggle_value boolean
---@param disabled_value boolean
---@param refs table?
local function render_top_rows(content_width, active_nav, toggle_value, disabled_value, refs)
	if content_width >= THREE_COLUMN_MIN_WIDTH then
		local compact = content_width < WIDE_TOP_ROW_WIDTH
		local card_width = compact and math.max((content_width - GAP * 2) / 3, 0) or 340
		local button_width = compact and 104 or 112
		local nav_width = compact and math.min(236, math.max(card_width - 36, 0)) or 236
		local label_width = compact and 80 or 120
		local value_width = compact and 44 or 80
		local row_gap = compact and 8 or 14

		view.hbox({
			width = "100%",
			height = 270,
			gap = GAP,
		}, function()
			render_buttons_card(card_width, button_width)
			render_navigation_card(card_width, nav_width, active_nav)
			render_toggle_card({
				ref = refs and refs.toggle_card,
				width = compact and card_width or nil,
				flex = compact and nil or 1,
				height = "100%",
			}, label_width, value_width, row_gap, toggle_value, disabled_value, refs)
		end)
		return
	end

	local card_width = math.max((content_width - GAP) / 2, 0)
	local nav_width = math.min(236, math.max(card_width - 36, 0))
	view.hbox({
		width = "100%",
		height = 270,
		gap = GAP,
	}, function()
		render_buttons_card(card_width, 104)
		render_navigation_card(card_width, nav_width, active_nav)
	end)
	render_toggle_card({
		ref = refs and refs.toggle_card,
		width = content_width,
		height = 150,
	}, 120, 80, 14, toggle_value, disabled_value, refs)
end

---@param content_width number
---@param size_value string
---@param open boolean
local function render_bottom_rows(content_width, size_value, open)
	local row = content_width >= BOTTOM_ROW_MIN_WIDTH
	local select_width = row and 420 or content_width

	local function render_select_card()
		card("Select", "Menu is an overlay and does not change card height.", {
			width = select_width,
			height = "100%",
		}, function()
			view.mount("view/select", {
				width = math.min(280, select_width),
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
	end

	local function render_composition_card(layout)
		card("Composition", "Owner state flows down as snapshot props.", layout, function()
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
	end

	if row then
		view.hbox({
			width = "100%",
			height = 250,
			gap = GAP,
		}, function()
			render_select_card()
			render_composition_card {
				flex = 1,
				height = "100%",
			}
		end)
		return
	end

	render_select_card()
	render_composition_card {
		width = content_width,
		height = 180,
	}
end

return function()
	local width = assert(args.width)
	local height = assert(args.height)
	local active_nav = selected_nav()
	local size_value = selected_size()
	local open = select_open()
	local toggle_value = enabled_toggle()
	local disabled_value = disabled_toggle()
	local refs = args.refs
	local content_width = math.min(math.max(width - PAGE_PADDING * 2, 0), CONTENT_WIDTH)

	view.vbox({
		width = width,
		height = height,
		background = PAGE_BG,
		padding = PAGE_PADDING,
		alignItems = "center",
		justify = "center",
	}, function()
		view.vbox({
			width = content_width,
			gap = GAP,
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
			render_top_rows(content_width, active_nav, toggle_value, disabled_value, refs)
			render_bottom_rows(content_width, size_value, open)
		end)
	end)
end
