local M = {}

function M.setup()
    require("core.options").setup()
    require("core.keymaps").setup()
    require("core.autocmds").setup()
end

return M
