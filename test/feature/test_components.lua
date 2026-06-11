local M = {}

function M.app(args)
	return require "test.feature.components_app" (args)
end

return M
