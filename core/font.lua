local datalist = require "soluna.datalist"
local file = require "soluna.file"
local soluna = require "soluna"
local font = require "soluna.font"

local manifest <const> = datalist.parse(assert(file.load "asset/font.dl"))

local load; do
	local function load_system(name)
		local fontid = font.name(name)
		if fontid then
			return {
				id = fontid,
				name = name,
			}
		end
		local sysfont = require "soluna.font.system"
		local data = assert(sysfont.ttfdata(name))
		font.import(data)
		fontid = assert(font.name(name))
		return {
			id = fontid,
			name = name,
		}
	end

	local function load_file(item)
		local data = assert(file.load(item.path))
		font.import(data)
		local fontid = assert(font.name(item.family))
		return {
			id = fontid,
			name = item.family
		}
	end

	function load()
		local fonts = assert(manifest.fonts)
		local conf = assert(fonts[soluna.platform])

		local loaded
		if conf.system then
			loaded = load_system(conf.system)
		elseif conf.file then
			loaded = load_file(conf.file)
		end

		load = function()
			return loaded
		end

		return loaded
	end
end

local M = {}

M.load = load

return M
