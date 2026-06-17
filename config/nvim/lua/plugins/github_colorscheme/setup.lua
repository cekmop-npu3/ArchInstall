local M = {}

function M.setup()
    local ok_github, github_theme = pcall(require, "github-theme")
    if not ok_github then
        return
    end

    github_theme.setup({})
    vim.cmd("colorscheme github_dark_dimmed")
end

return M
