
local M = {}


function M.on_attach(ev, client)
    local opts = { buffer = ev.buf, silent = true }

    if client:supports_method("textDocument/hover") then
        vim.keymap.set("n", "<leader>h", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP hover" }))
    end

    if client:supports_method("textDocument/signatureHelp") then
        vim.keymap.set("i", "<C-space>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP signature help" }))

        local ok, lsp_signature = pcall(require, "plugins.lsp_signature.setup")
        if ok and lsp_signature and type(lsp_signature.attach) == "function" then
            lsp_signature.attach(ev.buf)
        end
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

    local telescope_keymaps = require("plugins.telescope.keymaps")
    if telescope_keymaps and type(telescope_keymaps.on_lsp_attach) == "function" then
        telescope_keymaps.on_lsp_attach(ev, client)
    end
end

return M
