local M = {}

function M.setup()
    vim.keymap.set("n", "<leader>gco", "<cmd>GitConflictChooseOurs<CR>", { desc = "Conflict choose ours" })
    vim.keymap.set("n", "<leader>gct", "<cmd>GitConflictChooseTheirs<CR>", { desc = "Conflict choose theirs" })
    vim.keymap.set("n", "<leader>gcb", "<cmd>GitConflictChooseBoth<CR>", { desc = "Conflict choose both" })
    vim.keymap.set("n", "<leader>gcn", "<cmd>GitConflictNextConflict<CR>", { desc = "Next conflict" })
    vim.keymap.set("n", "<leader>gcp", "<cmd>GitConflictPrevConflict<CR>", { desc = "Previous conflict" })
end

return M
