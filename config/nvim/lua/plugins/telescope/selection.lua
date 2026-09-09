local M = {}

function M.attach_open_mappings(prompt_bufnr, map, open, commands)
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local function open_selected(command)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
            actions.close(prompt_bufnr)
            open(selection.value, command)
        end
    end

    actions.select_default:replace(function()
        open_selected(commands.current)
    end)

    for _, mapping in ipairs({
        { key = "<CR>", command = commands.current },
        { key = "<C-h>", command = commands.horizontal },
        { key = "<C-v>", command = commands.vertical },
        { key = "<C-t>", command = commands.tab },
    }) do
        local command = mapping.command
        for _, mode in ipairs({ "i", "n" }) do
            map(mode, mapping.key, function()
                open_selected(command)
            end)
        end
    end

    return true
end

return M
