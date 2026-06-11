local view = require "core.view"

local args = ...

local ROW_HEIGHT <const> = 24
local PAGE_BG <const> = 0xfff3f4f6
local PANEL_BG <const> = 0xffffffff
local TEXT <const> = 0xff111827
local MUTED <const> = 0xff6b7280
local LINE <const> = 0xffe5e7eb

local rows <const> = args.rows or 1000
---@class (partial) PerformanceDriver
---@field update_rows fun(step: integer): integer
---@field invalidate_parent fun()
---@field reset_rows fun()
---@type PerformanceDriver
local driver <const> = assert(args.driver)
---@type ViewValue<integer>[]
local values = {}

for i = 1, rows do
	values[i] = view.value(0)
end

local parent_revision = view.value(0)

function driver.update_rows(step)
	local changed = 0
	for i = step, rows, step do
		local value = values[i]
		---@cast value ViewValue<integer>
		value(value() + 1)
		changed = changed + 1
	end
	return changed
end

function driver.invalidate_parent()
	parent_revision(parent_revision() + 1)
end

function driver.reset_rows()
	for i = 1, rows do
		local value = values[i]
		---@cast value ViewValue<integer>
		value(0)
	end
	parent_revision(parent_revision() + 1)
end

return function()
	local revision = parent_revision()

	view.vbox({
		width = args.width,
		height = args.height,
		background = PAGE_BG,
		padding = 16,
		gap = 12,
	}, function()
		view.text("View Performance Benchmark", {
			width = "100%",
			height = 32,
			size = 24,
			color = TEXT,
			align = "LV",
		})
		view.text("Rows: " .. tostring(rows) .. "    Parent revisions: " .. tostring(revision), {
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
		view.vbox({
			width = "100%",
			height = rows * ROW_HEIGHT,
			background = PANEL_BG,
		}, function()
			for i = 1, #values do
				view.mount("test/feature/performance_row", {
					key = i,
					index = i,
					value = values[i],
					width = "100%",
					height = ROW_HEIGHT,
				})
			end
		end)
	end)
end
