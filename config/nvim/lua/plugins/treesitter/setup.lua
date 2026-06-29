local M = {}

function M.setup()
    local ok, treesitter = pcall(require, "nvim-treesitter.configs")
    if not ok then
        return
    end

    treesitter.setup({
        ensure_installed = {
            "markdown",
            "markdown_inline",
        },
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = {
            enable = true,
        },
    })
end

return M
