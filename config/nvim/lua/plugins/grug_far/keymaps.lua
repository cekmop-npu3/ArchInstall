local M = {}

function M.setup()
    local ok, grug = pcall(require, "grug-far")
    if not ok then
        return
    end

    vim.keymap.set("n", "<leader>fr", function()
        grug.open({})
    end, { desc = "Grug Far search and replace" })
end

return M
