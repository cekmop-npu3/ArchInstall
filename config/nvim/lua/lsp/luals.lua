vim.lsp.config['luals'] = {
   cmd = {'lua-language-server'},
   filetypes = {'lua'},
   root_markers = {'.luarc.json', '.luarc.jsonc', '.git'},
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
            globals = {"vim"}
         },
         hover = {
            enable = true,
            expandAlias = true
         },
         semantic = {
            enable = true
         },
         workspace = {
            library = vim.api.nvim_list_runtime_paths()
         },
         hint = {
             enable = true,
             paramName = "All",
             paramType = true,
             setType = true,
             arrayIndex = "Disable",
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
             version = "LuaJIT"
         }
     }
 }
}


vim.lsp.enable('luals')

