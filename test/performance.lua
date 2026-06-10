local app = require "soluna.app"
local font = require "core.font"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"
local soluna = require "soluna"
local sfont = require "soluna.font"

local args = ...
---@class PerformanceSettings
---@field perf_rows integer?
---@field perf_update_step integer?
---@field perf_parent_interval integer?
---@field smoke_frames integer?
---@type PerformanceSettings
local settings <const> = soluna.settings()

soluna.set_window_title "View Performance Benchmark"

local view = require "core.view".new {
	w = args.width,
	h = args.height,
}

local ROWS <const> = settings.perf_rows or 1000
local UPDATE_STEP <const> = settings.perf_update_step or 10
local PARENT_INTERVAL <const> = settings.perf_parent_interval or 60
local SMOKE_FRAMES <const> = settings.smoke_frames or 0
local FRAME_DT <const> = 1 / 60
local HUD_W <const> = 360
local HUD_H <const> = 150
local HUD_PADDING <const> = 12
local HUD_BG <const> = 0xeeffffff
local HUD_TEXT <const> = 0xff111827

local screen = {
	w = args.width,
	h = args.height,
}
---@class (partial) PerformanceDriver
---@field update_rows fun(step: integer): integer
---@field invalidate_parent fun()
---@field reset_rows fun()
---@type PerformanceDriver
---@diagnostic disable-next-line: missing-fields
local driver = {}
local root = view:mount("test/performance_root", {
	width = args.width,
	height = args.height,
	rows = ROWS,
	driver = driver,
})

local batch <const> = args.batch
local fontid <const> = assert(font.load()).id
local hud_text <const> = mattext.block(sfont.cobj(), fontid, 14, HUD_TEXT, "LV")
local hud_label
local hud_source
local frame = 0

local function ms(from_clock, to_clock)
	return (to_clock - from_clock) * 1000
end

local function metric(value)
	return string.format("%.3f", value)
end

local function draw_hud(update_ms, draw_ms, changed, render_delta, render_total)
	local text = table.concat({
		"View performance",
		"rows: " .. tostring(ROWS),
		"updated rows/frame: " .. tostring(changed),
		"render effects/frame: " .. tostring(render_delta),
		"render effects total: " .. tostring(render_total),
		"view:update ms: " .. metric(update_ms),
		"view:draw ms: " .. metric(draw_ms),
	}, "\n")
	if text ~= hud_source then
		hud_source = text
		hud_label = hud_text(text, HUD_W - HUD_PADDING * 2, HUD_H - HUD_PADDING * 2)
	end
	local x = math.max(screen.w - HUD_W - 16, 0)
	local y = 16
	batch:add(matquad.quad(HUD_W, HUD_H, HUD_BG), x, y)
	batch:add(hud_label, x + HUD_PADDING, y + HUD_PADDING)
end

local C = {}

function C.window_resize(w, h)
	screen.w = w
	screen.h = h
	view:resize(w, h)
	root.args.width = w
	root.args.height = h
end

function C.frame()
	frame = frame + 1
	local before = view:statistics().render_count
	local t0 = os.clock()
	local changed = driver.update_rows(UPDATE_STEP)
	if PARENT_INTERVAL > 0 and frame % PARENT_INTERVAL == 0 then
		driver.invalidate_parent()
	end
	view:update(FRAME_DT)
	local t1 = os.clock()
	view:draw(batch)
	local t2 = os.clock()
	local render_total = view:statistics().render_count
	draw_hud(ms(t0, t1), ms(t1, t2), changed, render_total - before, render_total)

	if SMOKE_FRAMES > 0 and frame >= SMOKE_FRAMES then
		app.quit()
	end
end

return C
