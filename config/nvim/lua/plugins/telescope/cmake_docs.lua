local M = {}

local categories = {
    { label = "command", list = "--help-command-list", help = "--help-command" },
    { label = "module", list = "--help-module-list", help = "--help-module" },
    { label = "variable", list = "--help-variable-list", help = "--help-variable" },
    { label = "property", list = "--help-property-list", help = "--help-property" },
    { label = "policy", list = "--help-policy-list", help = "--help-policy" },
}

local function show_documentation(entry, open_command)
    local result = vim.system({ "cmake", entry.help, entry.name }, { text = true }):wait()
    if result.code ~= 0 then
        local message = result.stderr and result.stderr ~= "" and result.stderr or result.stdout or "CMake documentation lookup failed"
        vim.notify(vim.trim(message), vim.log.levels.WARN)
        return
    end

    vim.cmd(open_command)
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].filetype = "rst"
    vim.api.nvim_buf_set_name(buffer, ("CMake %s: %s"):format(entry.label, entry.name))
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(result.stdout or "", "\n", { plain = true }))
    vim.bo[buffer].modifiable = false
end

function M.open()
    if vim.fn.executable("cmake") ~= 1 then
        vim.notify("cmake is not available on PATH", vim.log.levels.ERROR)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local config = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entries = {}

    for _, category in ipairs(categories) do
        local names = vim.fn.systemlist({ "cmake", category.list })
        if vim.v.shell_error == 0 then
            for _, name in ipairs(names) do
                if name ~= "" and not name:find("<", 1, true) then
                    entries[#entries + 1] = {
                        name = name,
                        label = category.label,
                        help = category.help,
                    }
                end
            end
        end
    end

    pickers.new({}, {
        prompt_title = "CMake Documentation",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = ("%-34s [%s]"):format(entry.name, entry.label),
                    ordinal = entry.name .. " " .. entry.label,
                }
            end,
        }),
        sorter = config.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry)
                local value = entry.value
                local result = vim.system({ "cmake", value.help, value.name }, { text = true }):wait()
                local output = result.code == 0 and result.stdout or result.stderr or "Documentation preview failed"
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output or "", "\n", { plain = true }))
                vim.bo[self.state.bufnr].filetype = "rst"
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            local function open_selected(open_command)
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    actions.close(prompt_bufnr)
                    show_documentation(selection.value, open_command)
                end
            end

            actions.select_default:replace(function()
                open_selected("enew")
            end)
            map("i", "<CR>", function()
                open_selected("enew")
            end)
            map("n", "<CR>", function()
                open_selected("enew")
            end)
            map("i", "<C-h>", function()
                open_selected("new")
            end)
            map("n", "<C-h>", function()
                open_selected("new")
            end)
            map("i", "<C-v>", function()
                open_selected("vnew")
            end)
            map("n", "<C-v>", function()
                open_selected("vnew")
            end)
            map("i", "<C-t>", function()
                open_selected("tabnew")
            end)
            map("n", "<C-t>", function()
                open_selected("tabnew")
            end)
            return true
        end,
    }):find()
end

return M
