
local M = {}


function M.setup()
    local gitsigns = require("gitsigns")
    if not gitsigns then
        return
    end

    gitsigns.setup({
        current_line_blame_opts = {
            delay = 500,
        },
    })
end

return M
