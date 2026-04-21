
local M = {}

local utils = require("core.utils")

function M.setup()
    utils.safe_setup("core.options")
    utils.safe_setup("core.keymaps")
    utils.safe_setup("core.autocmds")
end

return M
