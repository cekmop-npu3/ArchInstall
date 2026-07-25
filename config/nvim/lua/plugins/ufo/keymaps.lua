local M = {}

function M.setup()
    local ok, ufo = pcall(require, "ufo")
    if not ok then
        return
    end

    vim.keymap.set("n", "zf", "zf", { desc = "Create fold with motion" })
    vim.keymap.set("x", "zf", "zf", { desc = "Create fold from selection" })

    vim.keymap.set({ "n", "x" }, "zo", "zo", { desc = "Open one fold level" })
    vim.keymap.set({ "n", "x" }, "zO", "zO", { desc = "Open folds recursively" })
    vim.keymap.set({ "n", "x" }, "zc", "zc", { desc = "Close one fold level" })
    vim.keymap.set({ "n", "x" }, "zC", "zC", { desc = "Close folds recursively" })
    vim.keymap.set("n", "za", "za", { desc = "Toggle one fold level" })
    vim.keymap.set("n", "zA", "zA", { desc = "Toggle folds recursively" })

    vim.keymap.set({ "n", "x" }, "zd", "zd", { desc = "Delete one manual fold level" })
    vim.keymap.set({ "n", "x" }, "zD", "zD", { desc = "Delete manual folds recursively" })
    vim.keymap.set("n", "zE", "zE", { desc = "Delete all manual folds" })

    vim.keymap.set("n", "zi", "zi", { desc = "Toggle folding" })

    vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
    vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
end

return M
