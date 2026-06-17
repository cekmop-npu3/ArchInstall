local M = {}

function M.setup()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local ok_tree, nvim_tree = pcall(require, "nvim-tree")
    if not ok_tree then
        return
    end

    nvim_tree.setup({
        on_attach = require("plugins.nvim_tree.keymaps").on_attach,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        update_focused_file = {
            enable = true,
            update_root = false,
        },
        view = {
            width = 36,
            preserve_window_proportions = true,
        },
        renderer = {
            root_folder_label = false,
        },
        filters = {
            dotfiles = false,
        },
        git = {
            ignore = false,
        },
    })

    require("plugins.nvim_tree.keymaps").setup()
end

return M
