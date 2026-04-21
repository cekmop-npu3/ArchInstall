
local M = {}


function M.setup()
    local kanagawa = require("kanagawa")
    if not kanagawa then
        return
    end

    kanagawa.setup({
        transparent = true,
        undercurl = true,
    })

    pcall(vim.cmd, "colorscheme kanagawa")
end

return M
