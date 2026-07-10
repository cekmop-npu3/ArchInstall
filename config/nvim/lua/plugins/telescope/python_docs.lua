local M = {}

local symbol_script = [[
import builtins
import pkgutil
import sys

symbols = {(name, f"builtins.{name}") for name in dir(builtins) if not name.startswith("_")}
symbols.update((name, name) for name in sys.stdlib_module_names if not name.startswith("_"))
symbols.update((module.name, module.name) for module in pkgutil.iter_modules() if not module.name.startswith("_"))
for name, target in sorted(symbols):
    print(f"{name}\t{target}")
]]

local documentation_script = [[
import inspect
import pydoc
import sys

target = sys.argv[1]
obj = pydoc.locate(target)
if obj is None:
    raise SystemExit(f"No Python documentation found for {target}")

try:
    source = inspect.getsourcefile(obj) or inspect.getfile(obj)
except (TypeError, OSError):
    source = None

if source:
    print(f"Source: {source}\n")
print(pydoc.plain(pydoc.render_doc(obj, title="Python documentation for %s")))
]]

local function python_command()
    return vim.fn.exepath("python3") ~= "" and "python3" or "python"
end

local function show_documentation(target, open_command)
    local result = vim.system({ python_command(), "-c", documentation_script, target }, { text = true }):wait()
    if result.code ~= 0 then
        local message = result.stderr and result.stderr ~= "" and result.stderr or result.stdout or "Documentation lookup failed"
        vim.notify(vim.trim(message), vim.log.levels.WARN)
        return
    end

    vim.cmd(open_command)
    local buffer = vim.api.nvim_get_current_buf()
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.bo[buffer].filetype = "man"
    vim.api.nvim_buf_set_name(buffer, "Python documentation: " .. target)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(result.stdout, "\n", { plain = true }))
    vim.bo[buffer].modifiable = false
end

function M.open()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local config = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local lines = vim.fn.systemlist({ python_command(), "-c", symbol_script })
    if vim.v.shell_error ~= 0 then
        vim.notify("Unable to query the active Python interpreter", vim.log.levels.ERROR)
        return
    end

    local entries = {}
    for _, line in ipairs(lines) do
        local name, target = line:match("^([^\t]+)\t(.+)$")
        if name and target then
            entries[#entries + 1] = { name = name, target = target }
        end
    end

    pickers.new({}, {
        prompt_title = "Python Documentation",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.name,
                    ordinal = entry.name .. " " .. entry.target,
                }
            end,
        }),
        sorter = config.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry)
                local result = vim.system({ python_command(), "-c", documentation_script, entry.value.target }, { text = true }):wait()
                local output = result.code == 0 and result.stdout or result.stderr or "Documentation preview failed"
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(output or "", "\n", { plain = true }))
                vim.bo[self.state.bufnr].filetype = "man"
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            local function selected_target()
                local selection = action_state.get_selected_entry()
                return selection and selection.value and selection.value.target
            end

            local function view_docs(open_command)
                local target = selected_target()
                if target then
                    actions.close(prompt_bufnr)
                    show_documentation(target, open_command)
                end
            end

            -- Match the selection mappings configured for the other Telescope
            -- pickers: Enter uses the current window and C-h opens a split.
            actions.select_default:replace(function()
                view_docs("enew")
            end)
            map("i", "<CR>", function()
                view_docs("enew")
            end)
            map("n", "<CR>", function()
                view_docs("enew")
            end)
            map("i", "<C-h>", function()
                view_docs("new")
            end)
            map("n", "<C-h>", function()
                view_docs("new")
            end)
            map("i", "<C-v>", function()
                view_docs("vnew")
            end)
            map("n", "<C-v>", function()
                view_docs("vnew")
            end)
            map("i", "<C-t>", function()
                view_docs("tabnew")
            end)
            map("n", "<C-t>", function()
                view_docs("tabnew")
            end)
            return true
        end,
    }):find()
end

return M
