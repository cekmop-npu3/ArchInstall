
local M = {}

local utils = require("core.utils")

function M.setup()
    utils.safe_setup("lsp.servers.lua_ls")
    utils.safe_setup("lsp.servers.clangd")
    utils.safe_setup("lsp.servers.cmake_ls")

    local lsp_keymaps = require("lsp.keymaps")

    vim.diagnostic.config({
        virtual_lines = { current_line = true },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
    })

    local function on_lsp_attach(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end

        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        if lsp_keymaps and type(lsp_keymaps.on_attach) == "function" then
            lsp_keymaps.on_attach(ev, client)
        end
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = on_lsp_attach,
    })

    local function safe_enable(name)
        pcall(vim.lsp.enable, name)
    end

    safe_enable("clangd")
    safe_enable("cmakels")
    safe_enable("lua_ls")
    safe_enable("luals")
    safe_enable("bashls")
    safe_enable("jdtls")
end

return M
