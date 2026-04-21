local M = {}


function M.setup()
    local builtin = require("telescope.builtin")
    if not builtin then
        return
    end

    local ok_pickers, pickers = pcall(require, "telescope.pickers")
    local ok_finders, finders = pcall(require, "telescope.finders")
    local ok_actions, actions = pcall(require, "telescope.actions")
    local ok_action_state, action_state = pcall(require, "telescope.actions.state")
    local ok_config, config = pcall(require, "telescope.config")
    if not (ok_pickers and ok_finders and ok_actions and ok_action_state and ok_config) then
        return
    end

    local function command_history_picker()
        local entries = {}
        local max_history = vim.fn.histnr(":")
        for i = max_history, 1, -1 do
            local cmd = vim.fn.histget(":", i)
            if cmd ~= nil and cmd ~= "" then
                table.insert(entries, cmd)
            end
        end

        pickers.new({}, {
            prompt_title = "Command History",
            finder = finders.new_table({
                results = entries,
            }),
            sorter = config.values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                local function execute_selected()
                    local selection = action_state.get_selected_entry()
                    if not selection or not selection[1] then
                        return
                    end

                    actions.close(prompt_bufnr)
                    vim.cmd(selection[1])
                end

                map("i", "<CR>", execute_selected)
                map("n", "<CR>", execute_selected)
                return true
            end,
        }):find()
    end

    vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({
            hidden = true,
        })
    end, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Telescope keymaps" })
    vim.keymap.set("n", "<leader>fQ", command_history_picker, { desc = "Command history (Telescope)" })
    vim.keymap.set("n", "<leader>fa", function()
        local search_path = vim.fn.input("Search path: ", "/", "dir")
        if search_path == "" then
            return
        end

        builtin.live_grep({
            prompt_title = "System Search: " .. search_path,
            search_dirs = { search_path },
            additional_args = function()
                return { "--hidden", "--no-ignore", "--follow" }
            end,
        })
    end, { desc = "Telescope system search" })
end

function M.on_lsp_attach(ev, client)
    local ok_builtin, builtin = pcall(require, "telescope.builtin")
    if not ok_builtin then
        return
    end

    local opts = { buffer = ev.buf, silent = true }

    if client:supports_method("textDocument/definition") then
        if type(builtin.lsp_definitions) == "function" then
            vim.keymap.set("n", "<leader>df", builtin.lsp_definitions, vim.tbl_extend("force", opts, { desc = "LSP definitions" }))
        end
    end

    if client:supports_method("textDocument/declaration") then
        if type(builtin.lsp_declarations) == "function" then
            vim.keymap.set("n", "<leader>de", builtin.lsp_declarations, vim.tbl_extend("force", opts, { desc = "LSP declarations" }))
        else
            vim.keymap.set("n", "<leader>de", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "LSP declarations" }))
        end
    end

    if client:supports_method("textDocument/implementation") then
        if type(builtin.lsp_implementations) == "function" then
            vim.keymap.set("n", "<leader>i", builtin.lsp_implementations, vim.tbl_extend("force", opts, { desc = "LSP implementations" }))
        end
    end

    if client:supports_method("textDocument/typeDefinition") then
        if type(builtin.lsp_type_definitions) == "function" then
            vim.keymap.set("n", "<leader>t", builtin.lsp_type_definitions, vim.tbl_extend("force", opts, { desc = "LSP type definitions" }))
        end
    end

    if client:supports_method("textDocument/references") then
        if type(builtin.lsp_references) == "function" then
            vim.keymap.set("n", "<leader>re", builtin.lsp_references, vim.tbl_extend("force", opts, { desc = "LSP references" }))
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
