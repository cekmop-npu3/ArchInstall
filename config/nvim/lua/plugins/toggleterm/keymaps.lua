local M = {}

function M.setup()
    vim.keymap.set("n", "<leader>t", function()
        local Terminal = require("toggleterm.terminal").Terminal

        Terminal
            :new({
                direction = "tab",
                size = 15,
            })
            :toggle()
    end, { desc = "Open fresh terminal" })
end

return M
