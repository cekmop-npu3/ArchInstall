require("options")
require("keymaps")
require("autocmd")
require("lsp")
require("lsp.luals")
require("lsp.clangd")
require("lsp.cmakels")
require("kanagawa").setup({
    transparent = true,
    undercurl = true
})
require("gitsigns").setup({
    current_line_blame_opts = {
        delay = 500
    }
})


vim.cmd("colorscheme kanagawa")

