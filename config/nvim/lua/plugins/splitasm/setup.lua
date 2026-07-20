local M = {}

function M.setup()
    local ok, splitasm = pcall(require, "splitasm")
    if not ok then
        return
    end

    splitasm.setup({
        auto_sync = true,
        hide_address = false,
        source_row_colors = true,
        show_line_numbers = true,
    })

    require("plugins.splitasm.keymaps").setup()
end

return M
