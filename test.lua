local runner = require "test.runner"

local args = ...

local kind = os.getenv and os.getenv "TEST_KIND" or nil
if kind == nil or kind == "" then
	kind = "smoke"
end

return runner.run(kind, args)
