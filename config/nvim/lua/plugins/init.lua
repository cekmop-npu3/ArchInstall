local M = {}

local utils = require("core.utils")

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
        { src = "https://github.com/ray-x/lsp_signature.nvim.git" },
        { src = "https://github.com/rebelot/kanagawa.nvim.git" },
        { src = "https://github.com/lewis6991/gitsigns.nvim" },
        { src = "https://github.com/sindrets/diffview.nvim.git" },
        { src = "https://github.com/akinsho/git-conflict.nvim.git" },
        { src = "https://github.com/numToStr/Comment.nvim.git" },
        { src = "https://github.com/kevinhwang91/promise-async.git" },
        { src = "https://github.com/kevinhwang91/nvim-ufo.git" },
        {
            src = "https://github.com/JavaHello/spring-boot.nvim",
            version = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
        },
        { src = "https://github.com/MunifTanjim/nui.nvim" },
        { src = "https://github.com/mfussenegger/nvim-dap" },
        { src = "https://github.com/nvim-java/nvim-java" },
        { src = "https://github.com/mikavilpas/yazi.nvim.git" },
    })

    if not ok_add then
        vim.notify(("Failed adding plugins: %s"):format(err), vim.log.levels.WARN)
        return
    end

    local plugin_modules = {
        "plugins.kanagawa",
        "plugins.cmp",
        "plugins.lsp_signature",
        "plugins.comment",
        "plugins.telescope",
        "plugins.grug_far",
        "plugins.gitsigns",
        "plugins.diffview",
        "plugins.git_conflict",
        "plugins.ufo",
        "plugins.java",
        "plugins.yazi",
    }

    for _, plugin in ipairs(plugin_modules) do
        utils.safe_setup(plugin .. ".setup")
        utils.safe_setup(plugin .. ".keymaps", { optional = true })
    end
end

return M
