local M = {}

local function with_picker_opts(picker, extra_opts)
    return function()
        picker(extra_opts)
    end
end

function M.setup()
    local builtin = require("telescope.builtin")
    if not builtin then
        return
    end

    vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({
            hidden = true,
        })
    end, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Telescope keymaps" })
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

    local documentation_pickers = {
        python = {
            description = "Python documentation lookup",
            open = require("plugins.telescope.python_docs").open,
        },
        lua = {
            description = "Lua documentation lookup",
            open = function()
                local actions = require("telescope.actions")
                local action_state = require("telescope.actions.state")
                builtin.help_tags({ prompt_title = "Lua Documentation" })

                local prompt_bufnr = vim.api.nvim_get_current_buf()
                local function open_selected(mode)
                    local selection = action_state.get_selected_entry()
                    if not selection or not selection.value then
                        return
                    end

                    local tag = selection.value
                    actions.close(prompt_bufnr)

                    if mode == "current" then
                        local origin = vim.api.nvim_get_current_win()
                        vim.cmd.help(tag)
                        local help_window = vim.api.nvim_get_current_win()
                        local help_buffer = vim.api.nvim_get_current_buf()
                        local help_view = vim.fn.winsaveview()
                        if origin ~= help_window and vim.api.nvim_win_is_valid(origin) then
                            vim.api.nvim_win_set_buf(origin, help_buffer)
                            vim.api.nvim_win_close(help_window, true)
                            vim.api.nvim_set_current_win(origin)
                            vim.fn.winrestview(help_view)
                        end
                    elseif mode == "horizontal" then
                        vim.cmd.help(tag)
                    elseif mode == "vertical" then
                        vim.cmd("vertical help " .. vim.fn.fnameescape(tag))
                    elseif mode == "tab" then
                        vim.cmd("tab help " .. vim.fn.fnameescape(tag))
                    end
                end

                local picker_mappings = {
                    ["<CR>"] = "current",
                    ["<C-h>"] = "horizontal",
                    ["<C-v>"] = "vertical",
                    ["<C-t>"] = "tab",
                }
                for key, mode in pairs(picker_mappings) do
                    local selected_mode = mode
                    vim.keymap.set({ "i", "n" }, key, function()
                        open_selected(selected_mode)
                    end, { buffer = prompt_bufnr, silent = true })
                end
            end,
        },
        sh = {
            description = "Shell documentation lookup",
            open = function()
                require("plugins.telescope.man_docs").open({
                    prompt_title = "Shell Documentation",
                    sections = { "1", "5", "7" },
                })
            end,
        },
        c = {
            description = "C documentation lookup",
            open = function()
                require("plugins.telescope.man_docs").open({
                    prompt_title = "C Documentation",
                    sections = { "2", "3" },
                })
            end,
        },
        cmake = {
            description = "CMake documentation lookup",
            open = require("plugins.telescope.cmake_docs").open,
        },
    }

    local documentation_group = vim.api.nvim_create_augroup("TelescopeLanguageDocumentation", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = documentation_group,
        pattern = vim.tbl_keys(documentation_pickers),
        callback = function(ev)
            local picker = documentation_pickers[vim.bo[ev.buf].filetype]
            if picker then
                vim.keymap.set("n", "<leader>ld", picker.open, {
                    buffer = ev.buf,
                    silent = true,
                    desc = picker.description,
                })
            end
        end,
    })
end

function M.on_lsp_attach(ev, client)
    local ok_builtin, builtin = pcall(require, "telescope.builtin")
    if not ok_builtin then
        return
    end

    local lsp_picker_opts = {
        jump_type = "never",
    }

    local opts = { buffer = ev.buf, silent = true }

    if client:supports_method("textDocument/definition") then
        if type(builtin.lsp_definitions) == "function" then
            vim.keymap.set("n", "<leader>df", with_picker_opts(builtin.lsp_definitions, lsp_picker_opts), vim.tbl_extend("force", opts, { desc = "LSP definitions" }))
        end
    end

    if client:supports_method("textDocument/implementation") then
        if type(builtin.lsp_implementations) == "function" then
            vim.keymap.set("n", "<leader>i", with_picker_opts(builtin.lsp_implementations, lsp_picker_opts), vim.tbl_extend("force", opts, { desc = "LSP implementations" }))
        end
    end

    if client:supports_method("textDocument/typeDefinition") then
        if type(builtin.lsp_type_definitions) == "function" then
            vim.keymap.set("n", "<leader>dt", with_picker_opts(builtin.lsp_type_definitions, lsp_picker_opts), vim.tbl_extend("force", opts, { desc = "LSP type definitions" }))
        end
    end

    if client:supports_method("textDocument/references") then
        if type(builtin.lsp_references) == "function" then
            vim.keymap.set("n", "<leader>re", with_picker_opts(builtin.lsp_references, lsp_picker_opts), vim.tbl_extend("force", opts, { desc = "LSP references" }))
        end
    end

    if client:supports_method("textDocument/documentSymbol") then
        if type(builtin.lsp_document_symbols) == "function" then
            vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, vim.tbl_extend("force", opts, { desc = "LSP document symbols" }))
        end
    end

    if client:supports_method("workspace/symbol") then
        if type(builtin.lsp_dynamic_workspace_symbols) == "function" then
            vim.keymap.set("n", "<leader>s", builtin.lsp_dynamic_workspace_symbols, vim.tbl_extend("force", opts, { desc = "LSP workspace symbols" }))
        end
    end
end

return M
