
local M = {}


function M.setup()
    local api = require("Comment.api")
    if not api then
        return
    end

    vim.keymap.set("n", "<leader>/", api.toggle.linewise.current, { silent = true, desc = "Comment toggle line" })
    vim.keymap.set("x", "<leader>/", function()
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        api.toggle.blockwise(vim.fn.visualmode())
    end, { silent = true, desc = "Comment toggle selection" })
end

return M
