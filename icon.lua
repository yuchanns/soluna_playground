local richtext = require "soluna.text"

local M = {}

function M.init(bundle)
	richtext.init(assert(bundle, "missing icon bundle"))
end

return M
