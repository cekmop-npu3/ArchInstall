local M = {}

function M.setup()
    local ok, diffview = pcall(require, "diffview")
    if not ok then
        return
    end

    diffview.setup({
        use_icons = false,
    })
end

return M
