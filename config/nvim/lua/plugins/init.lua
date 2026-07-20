local M = {}

function M.setup()
    local ok_add, err = pcall(vim.pack.add, {
        { src = "https://github.com/neovim/nvim-lspconfig.git" },
        { src = "https://github.com/nvim-telescope/telescope.nvim.git" },
        { src = "https://github.com/nvim-lua/plenary.nvim.git" },

        { src = "https://github.com/hrsh7th/nvim-cmp.git" },
        { src = "https://github.com/hrsh7th/cmp-nvim-lsp.git" },
        { src = "https://github.com/hrsh7th/cmp-buffer.git" },
        { src = "https://github.com/hrsh7th/cmp-path.git" },
        { src = "https://github.com/hrsh7th/cmp-cmdline.git" },

        { src = "https://github.com/MagicDuck/grug-far.nvim.git" },
        { src = "https://github.com/lewis6991/gitsigns.nvim" },
        { src = "https://github.com/sindrets/diffview.nvim.git" },
        { src = "https://github.com/akinsho/git-conflict.nvim.git" },
        { src = "https://github.com/numToStr/Comment.nvim.git" },
        { src = "https://github.com/kevinhwang91/promise-async.git" },
        { src = "https://github.com/kevinhwang91/nvim-ufo.git" },
        { src = "https://github.com/mfussenegger/nvim-dap" },
        { src = "https://github.com/folke/noice.nvim.git" },
        { src = "https://github.com/MunifTanjim/nui.nvim.git" },
        { src = "https://github.com/rcarriga/nvim-notify.git" },
        { src = "https://github.com/nvim-tree/nvim-tree.lua.git" },
        { src = "https://github.com/nvim-tree/nvim-web-devicons.git" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter.git" },
        { src = "https://github.com/nvim-lualine/lualine.nvim.git" },
        { src = "https://github.com/goolord/alpha-nvim.git" },
        { src = "https://github.com/projekt0n/github-nvim-theme.git" },
        { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim.git" },
        { src = "https://github.com/brianhuster/live-preview.nvim.git" },
        { src = "https://github.com/NickTsaizer/splitasm.nvim.git" },
        { src = "https://github.com/akinsho/toggleterm.nvim.git" }
    })

    if not ok_add then
        vim.notify(("Failed adding plugins: %s"):format(err), vim.log.levels.WARN)
        return
    end

    local plugin_modules = {
        "plugins.comment",
        "plugins.telescope",
        "plugins.grug_far",
        "plugins.gitsigns",
        "plugins.diffview",
        "plugins.git_conflict",
        "plugins.ufo",
        "plugins.nvim_tree",
        "plugins.treesitter",
        "plugins.cmp",
        "plugins.github_colorscheme",
        "plugins.live_preview",
        "plugins.toggleterm",
        "plugins.popups",
        "plugins.noice",
        "plugins.render_markdown",
        "plugins.splitasm",
        "plugins.alpha",
        "plugins.lualine"
    }

    for _, plugin in ipairs(plugin_modules) do
        require(plugin .. ".setup").setup()
    end
end

return M
