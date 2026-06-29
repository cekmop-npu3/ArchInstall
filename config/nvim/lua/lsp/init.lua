local M = {}

function M.setup()
    local function on_lsp_attach(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        require("lsp.keymaps").on_attach(ev, client)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_lsp_attach,
    })

    vim.lsp.config["lua_ls"] = require("lsp.config.lua_ls")

    vim.lsp.enable("clangd")
    vim.lsp.enable("lua_ls")
    vim.lsp.enable("bashls")
    vim.lsp.enable("pylsp")
    vim.lsp.enable("neocmake")
end

return M
