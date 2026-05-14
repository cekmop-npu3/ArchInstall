local M = {}


function M.setup()
    local yazi = require("yazi")
    if not yazi then
        return
    end

    yazi.setup({
        open_for_directories = true,
        ---@diagnostic disable-next-line
        keymaps = {
            open_file_in_horizontal_split = "<C-h>",
            grep_in_directory = "<C-f>",
            replace_in_directory = "<C-r>",
            open_file_in_tab = "<C-t>",
            open_file_in_vertical_split = "<C-v>"
        }
    })
end

return M
