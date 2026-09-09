local M = {}

function M.setup()
    local builtin = require("telescope.builtin")
    local lsp_picker_opts = { jump_type = "never" }

    local function lsp_picker(picker)
        return function()
            picker(lsp_picker_opts)
        end
    end

    vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({ hidden = true })
    end, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Telescope keymaps" })
    vim.keymap.set("n", "<leader>df", lsp_picker(builtin.lsp_definitions), { desc = "LSP definitions" })
    vim.keymap.set("n", "<leader>i", lsp_picker(builtin.lsp_implementations), { desc = "LSP implementations" })
    vim.keymap.set("n", "<leader>dt", lsp_picker(builtin.lsp_type_definitions), { desc = "LSP type definitions" })
    vim.keymap.set("n", "<leader>re", lsp_picker(builtin.lsp_references), { desc = "LSP references" })
    vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "LSP document symbols" })
    vim.keymap.set("n", "<leader>s", builtin.lsp_dynamic_workspace_symbols, { desc = "LSP workspace symbols" })
    vim.keymap.set("n", "<leader>ld", require("plugins.telescope.documentation").open, { desc = "Language documentation" })
    vim.keymap.set("n", "<leader>fa", function()
        local search_path = vim.fn.input("Search path: ", "/", "dir")
        if search_path == "" then
            return
        end

        builtin.find_files({
            prompt_title = "System Search: " .. search_path,
            search_dirs = { search_path },
            additional_args = function()
                return { "--hidden", "--no-ignore", "--follow" }
            end,
        })
    end, { desc = "Telescope system search" })
end

return M
