local M = {}

function M.setup()
    local function on_lsp_attach(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
        require("lsp.keymaps").on_attach(ev, client)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_lsp_attach,
    })

    vim.lsp.config["lua_ls"] = require("lsp.config.lua_ls")
    vim.lsp.config["pyrefly"] = require("lsp.config.pyrefly")

    vim.lsp.enable("clangd")
    vim.lsp.enable("lua_ls")
    vim.lsp.enable("bashls")
    vim.lsp.enable("pyrefly")
    vim.lsp.enable("neocmake")
end

return M
