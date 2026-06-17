local M = {}

function M.setup()
    local ok, diffview = pcall(require, "diffview")
    if not ok then
        return
    end

    diffview.setup({
        use_icons = false,
    })

    require("plugins.diffview.keymaps").setup()
end

return M
