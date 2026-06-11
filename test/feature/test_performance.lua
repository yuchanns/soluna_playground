local M = {}

function M.app(args)
	return require "test.feature.performance_app" (args)
end

return M
