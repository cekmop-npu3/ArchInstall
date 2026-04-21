
local M = {}


function M.setup()
    local gitsigns = require("gitsigns")
    if not gitsigns then
        return
    end

    vim.keymap.set("n", "<leader>gb", gitsigns.toggle_current_line_blame, { desc = "Gitsigns toggle line blame" })
    vim.keymap.set("n", "<leader>gt", gitsigns.toggle_signs, { desc = "Gitsigns toggle signs" })
    vim.keymap.set("v", "<leader>gb", function()
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end

        gitsigns.blame_line({
            full = true,
            ignore_whitespace = true,
            line_start = start_line,
            line_end = end_line,
        })
    end, { desc = "Gitsigns blame selected lines" })
end

return M
