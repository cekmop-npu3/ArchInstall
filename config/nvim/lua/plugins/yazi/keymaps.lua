
local M = {}


function M.setup()
    local yazi = require("yazi")
    if not yazi then
        return
    end

    vim.keymap.set("n", "<leader>e", function()
        yazi.yazi()
    end, { desc = "Open Yazi" })
end

return M
