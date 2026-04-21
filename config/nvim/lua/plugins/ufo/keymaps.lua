local M = {}

function M.setup()
    local ok, ufo = pcall(require, "ufo")
    if not ok then
        return
    end

    vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
    vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
end

return M
