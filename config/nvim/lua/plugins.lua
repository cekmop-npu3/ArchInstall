vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/rebelot/kanagawa.nvim.git" },
    { src = "https://github.com/iamcco/markdown-preview.nvim.git" },
    { src = "https://github.com/neovim/nvim-lspconfig.git" }
})

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

