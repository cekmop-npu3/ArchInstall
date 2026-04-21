local M = {}


function M.setup()
    local telescope = require("telescope")
    if not telescope then
        return
    end

    local actions = require("telescope.actions")

    telescope.setup({
        defaults = {
            initial_mode = "normal",
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
                "--glob=!.git/*",
            },
            mappings = {
                i = {
                    ["<C-h>"] = actions.select_horizontal,
                    ["<C-x>"] = false,
                },
                n = {
                    ["K"] = actions.move_to_top,
                    ["J"] = actions.move_to_bottom,
                    ["<leader>k"] = actions.move_to_top,
                    ["<leader>j"] = actions.move_to_bottom,
                    ["<C-h>"] = actions.select_horizontal,
                    ["<C-x>"] = false,
                },
            },
        },
        pickers = {
            find_files = {
                hidden = true,
            },
        },
    })
end

return M
