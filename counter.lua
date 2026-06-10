local view = require "core.view"

local BUTTON_W <const> = 96
local BUTTON_H <const> = 48
local BUTTON_GAP <const> = 40
local BUTTON_TEXT_SIZE <const> = 18

local value = view.value
local args = ...

local w <const> = assert(args.width)
local h <const> = assert(args.height)

local count = value(0)

return function()
	view.box({
		width = w,
		height = h,
		background = 0xff4f7cff,
		padding = 2,
	}, function()
		view.vbox({
			width = "100%",
			height = "100%",
			background = 0xff202636,
			padding = 24,
		}, function()
			view.text("Reactive Counter", {
				width = "100%",
				height = 48,
				size = 28,
				color = 0xfff4f7ff,
				align = "CV",
			})
			view.text(function()
				return tostring(count())
			end, {
				width = "100%",
				height = 96,
				size = 72,
				color = 0xffffd166,
				align = "CV",
			})
			view.box {
				flex = 1,
			}
			view.hbox({
				width = "100%",
				height = BUTTON_H,
				gap = BUTTON_GAP,
				justify = "center",
			}, function()
				view.mount("button", {
					width = BUTTON_W,
					height = BUTTON_H,
					label = "-",
					color = 0xff374151,
					hover_color = 0xff4b5563,
					text_size = BUTTON_TEXT_SIZE,
					on_click = function()
						count(count() - 1)
					end,
				})
				view.mount("button", {
					width = BUTTON_W,
					height = BUTTON_H,
					label = "+",
					color = 0xff4f7cff,
					hover_color = 0xff6b91ff,
					text_size = BUTTON_TEXT_SIZE,
					on_click = function()
						count(count() + 1)
					end,
				})
			end)
		end)
	end)
end
