local app = require "soluna.app"
local file = require "soluna.file"

local M = {}

local function selected_name()
	local value = os.getenv and os.getenv "TEST_NAME"
	if value == "" then
		return nil
	end
	return value
end

local function collect(kind)
	local path = "test/" .. kind
	local names = {}
	for filename in file.dir(path) do
		local name = filename:match "^test_(.+)%.lua$"
		if name then
			names[#names + 1] = name
		end
	end
	table.sort(names)
	return names
end

local function load_case(kind, name)
	return require("test." .. kind .. ".test_" .. name)
end

local function run_cases(kind, args, names)
	local callback = {}
	local done = false

	function callback.frame()
		if done then
			return
		end
		done = true
		for i = 1, #names do
			local name = names[i]
			local case = load_case(kind, name)
			if case.run then
				case.run(args)
			elseif kind == "smoke" then
				error("smoke test " .. name .. " must expose run(args)", 2)
			end
		end
		app.quit()
	end

	return callback
end

function M.run(kind, args)
	local selected = selected_name()
	if selected then
		local case = load_case(kind, selected)
		if case.app then
			return case.app(args)
		end
		assert(case.run, kind .. " test " .. selected .. " must expose run(args) or app(args)")
		return run_cases(kind, args, {
			selected,
		})
	end
	return run_cases(kind, args, collect(kind))
end

return M
