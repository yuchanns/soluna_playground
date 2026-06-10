local view = require "core.view"
local pi = math.pi

local args = ...

local width <const> = args.width or 280
local row_height <const> = args.row_height or 36
local text_size <const> = args.text_size or 15
local icon_size <const> = args.icon_size or 16
local background <const> = args.background or 0xffffffff
local hover_background <const> = args.hover_background or 0xfff9fafb
local pressed_background <const> = args.pressed_background or 0xffeff6ff
local menu_background <const> = args.menu_background or 0xffffffff
local menu_gap <const> = args.menu_gap or 4
local text_color <const> = args.text_color or 0xff111827
local placeholder_color <const> = args.placeholder_color or 0xff9ca3af
local radius <const> = args.radius or 6
local option_radius <const> = args.option_radius or 4
local menu_padding <const> = args.menu_padding or 4

local hovered = view.hovered()
local pressed = view.pressed()
local arrow_rotation = view.animated(function()
	return args.open and pi or 0
end, {
	duration = 0.16,
	easing = "out_cubic",
})

view.clickable {
	enabled = args.enabled,
	on_click = function(event)
		if args.on_open_change then
			args.on_open_change(not args.open, event)
		end
	end,
}

local function selected_label()
	local options = args.options or {}
	for i = 1, #options do
		local item = options[i]
		if item.value == args.value then
			return item.label
		end
	end
	return args.placeholder or "Select"
end

return function()
	local open = args.open == true
	local rotation = arrow_rotation()
	local button_fill = background
	if pressed() then
		button_fill = pressed_background
	elseif hovered() then
		button_fill = hover_background
	end

	local options = args.options or {}
	local label = selected_label()
	local label_color = args.value and text_color or placeholder_color
	local menu_height = row_height * #options + math.max(#options - 1, 0) + menu_padding * 2

	view.box({
		width = width,
		height = row_height,
	}, function()
		view.mount("view/surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = row_height,
			fill = button_fill,
			radius = radius,
		})
		view.hbox({
			width = "100%",
			height = row_height,
			alignItems = "center",
			padding = 10,
			gap = 8,
		}, function()
			view.text(label, {
				flex = 1,
				height = "100%",
				size = text_size,
				color = label_color,
				align = "LV",
			})
			view.mount("view/icon", {
				width = 24,
				height = "100%",
				name = args.icon_right or "chevron_down",
				size = icon_size,
				color = 0xff6b7280,
				rotation = rotation,
			})
		end)

		view.transition({
			show = open,
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = 0,
			duration = 0.16,
			easing = "out_cubic",
		}, function(state)
			local progress = state.progress
			view.box({
				position = "absolute",
				left = 0,
				top = row_height + menu_gap + (1 - progress) * -6,
				width = "100%",
				height = menu_height,
			}, function()
				view.mount("view/surface", {
					position = "absolute",
					left = 0,
					top = 0,
					width = "100%",
					height = "100%",
					fill = menu_background,
					radius = radius,
				})
				view.vbox({
					width = "100%",
					height = "100%",
					padding = menu_padding,
					gap = 1,
				}, function()
					for i = 1, #options do
						local item = options[i]
						view.mount("view/select_option", {
							key = item.value,
							value = item.value,
							label = item.label,
							width = "100%",
							height = row_height,
							radius = option_radius,
							enabled = state.show,
							selected = item.value == args.value,
							on_select = args.on_change,
						})
					end
				end)
			end)
		end)
	end)
end
