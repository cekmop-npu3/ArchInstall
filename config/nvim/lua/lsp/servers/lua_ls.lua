
local M = {}

function M.setup()
    local lua_config = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
        settings = {
            Lua = {
                completion = {
                    enable = true,
                    callSnippet = "Both",
                    keywordSnippet = "Replace",
                    showWord = "Disable",
                    workspaceWord = false,
                },
                diagnostics = {
                    enable = true,
                    globals = { "vim" },
                },
                hover = {
                    enable = true,
                    expandAlias = true,
                },
                semantic = {
                    enable = true,
                },
                workspace = {
                    library = vim.api.nvim_list_runtime_paths(),
                },
                runtime = {
                    path = {
                        "lua/?.lua",
                        "lua/?/init.lua",
                        "?.lua",
                        "?/init.lua",
                        "plugins/?/init.lua",
                    },
                    pathStrict = false,
                    version = "LuaJIT",
                },
            },
        },
    }

    vim.lsp.config.lua_ls = lua_config
    vim.lsp.config.luals = lua_config
end

return M
