local M = {}

function M.on_attach(ev, client)
    local opts = { buffer = ev.buf, silent = true }

    if client:supports_method("textDocument/hover") then
        vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP hover" }))
    end

    if client:supports_method("textDocument/codeAction") then
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP code actions" }))
    end

    if client:supports_method("textDocument/rename") then
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP rename symbol" }))
    end

    if client:supports_method("textDocument/formatting") then
        vim.keymap.set("n", "<leader>o", function()
            vim.lsp.buf.format({ async = true })
        end, vim.tbl_extend("force", opts, { desc = "LSP format buffer" }))
    end

    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))

    local telescope_keymaps = require("plugins.telescope.keymaps")
    telescope_keymaps.on_lsp_attach(ev, client)
end

return M
