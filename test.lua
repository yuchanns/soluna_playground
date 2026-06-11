local runner = require "test.runner"

local args = ...

local kind = os.getenv and os.getenv "TEST_KIND" or nil

return runner.run(kind, args)
