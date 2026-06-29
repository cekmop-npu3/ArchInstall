local M = {}

function M.setup()
    local ok, toggleterm = pcall(require, "toggleterm")
    if not ok then
        return
    end

    toggleterm.setup({
        size = 15,
        direction = "tab",
        start_in_insert = false,
        persist_mode = true,
    })

    require("plugins.toggleterm.keymaps").setup(toggleterm.toggle)
end

return M
