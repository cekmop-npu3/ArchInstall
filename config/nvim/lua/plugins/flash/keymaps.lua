local M = {}

function M.setup()
    vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash: Jump to match" })

    vim.keymap.set("o", "r", function() require("flash").remote() end)
    vim.keymap.set({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
end

return M
