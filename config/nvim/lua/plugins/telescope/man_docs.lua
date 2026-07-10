local M = {}

local function installed_pages(sections)
    local entries = {}
    local seen = {}
    local manpath = vim.fn.system({ "manpath" })

    if vim.v.shell_error ~= 0 then
        return entries
    end

    for root in vim.gsplit(vim.trim(manpath), ":", { plain = true }) do
        for _, section in ipairs(sections) do
            local directory = root .. "/man" .. section
            if vim.fn.isdirectory(directory) == 1 then
                for name, entry_type in vim.fs.dir(directory) do
                    if entry_type == "file" then
                        local page = name:gsub("%.gz$", ""):gsub("%.bz2$", ""):gsub("%.xz$", "")
                        page = page:gsub("%." .. vim.pesc(section) .. "$", "")
                        local key = section .. "\0" .. page
                        if page ~= "" and not seen[key] then
                            seen[key] = true
                            entries[#entries + 1] = { name = page, section = section }
                        end
                    end
                end
            end
        end
    end

    table.sort(entries, function(left, right)
        return left.name == right.name and left.section < right.section or left.name < right.name
    end)
    return entries
end

function M.open(opts)
    opts = opts or {}
    local sections = opts.sections or { "1" }
    local entries = installed_pages(sections)
    if #entries == 0 then
        vim.notify("No installed man pages found in sections " .. table.concat(sections, ", "), vim.log.levels.WARN)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local config = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
        prompt_title = opts.prompt_title or "Manual Pages",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = ("%s(%s)"):format(entry.name, entry.section),
                    ordinal = entry.name .. " " .. entry.section,
                }
            end,
        }),
        sorter = config.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry)
                local page = entry.value
                local result = vim.system({ "man", page.section, page.name }, {
                    env = { MANPAGER = "cat", PAGER = "cat" },
                    text = true,
                }):wait()
                local output = result.code == 0 and result.stdout or result.stderr or "Manual-page preview failed"
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output or "", "\n", { plain = true }))
                vim.bo[self.state.bufnr].filetype = "man"
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            local function open_selected(command)
                local selection = action_state.get_selected_entry()
                if not selection or not selection.value then
                    return
                end

                actions.close(prompt_bufnr)
                local page = selection.value
                local uri = ("man://%s(%s)"):format(page.name, page.section)
                vim.cmd({ cmd = command, args = { uri } })
            end

            actions.select_default:replace(function()
                open_selected("edit")
            end)
            map("i", "<CR>", function()
                open_selected("edit")
            end)
            map("n", "<CR>", function()
                open_selected("edit")
            end)
            map("i", "<C-h>", function()
                open_selected("split")
            end)
            map("n", "<C-h>", function()
                open_selected("split")
            end)
            map("i", "<C-v>", function()
                open_selected("vsplit")
            end)
            map("n", "<C-v>", function()
                open_selected("vsplit")
            end)
            map("i", "<C-t>", function()
                open_selected("tabedit")
            end)
            map("n", "<C-t>", function()
                open_selected("tabedit")
            end)
            return true
        end,
    }):find()
end

return M
