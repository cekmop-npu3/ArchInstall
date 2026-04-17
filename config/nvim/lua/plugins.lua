vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/rebelot/kanagawa.nvim.git" },
    { src = "https://github.com/iamcco/markdown-preview.nvim.git" },
    { src = "https://github.com/neovim/nvim-lspconfig.git" }
})

vim.pack.add({
  {
    src = 'https://github.com/JavaHello/spring-boot.nvim',
    version = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
  },
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/mfussenegger/nvim-dap',

  'https://github.com/nvim-java/nvim-java',
})

require('java').setup()
vim.lsp.enable('jdtls')

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

vim.lsp.enable 'bashls'

