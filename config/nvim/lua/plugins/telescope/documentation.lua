local M = {}

local function open_man_docs(prompt_title, sections)
    require("plugins.telescope.man_docs").open({
        prompt_title = prompt_title,
        sections = sections,
    })
end

function M.open()
    if vim.fn.has("linux") == 0 and vim.bo.filetype ~= "lua" then
        vim.notify("External documentation pickers are only enabled on Linux", vim.log.levels.INFO)
        return
    end

    local pickers = {
        python = require("plugins.telescope.python_docs").open,
        lua = function()
            require("telescope.builtin").help_tags({ prompt_title = "Lua Documentation" })
        end,
        sh = function()
            open_man_docs("Shell Documentation", { "1", "5", "7" })
        end,
        bash = function()
            open_man_docs("Shell Documentation", { "1", "5", "7" })
        end,
        zsh = function()
            open_man_docs("Shell Documentation", { "1", "5", "7" })
        end,
        c = function()
            open_man_docs("C Documentation", { "2", "3" })
        end,
        cpp = function()
            open_man_docs("C Documentation", { "2", "3" })
        end,
        cmake = require("plugins.telescope.cmake_docs").open,
    }
    local picker = pickers[vim.bo.filetype]

    if picker then
        picker()
    else
        vim.notify("No documentation picker is configured for " .. vim.bo.filetype, vim.log.levels.INFO)
    end
end

return M
