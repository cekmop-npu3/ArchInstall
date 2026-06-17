local M = {}

function M.setup()
    local ok_alpha, alpha = pcall(require, "alpha")
    if not ok_alpha then
        return
    end

    local dashboard = require("alpha.themes.dashboard")

    dashboard.section.buttons.val = {
        dashboard.button("e", "Toggle Tree", "<Cmd>NvimTreeToggle<CR>"),
        dashboard.button("n", "New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "Find file", ":Telescope find_files <CR>"),
        dashboard.button("g", "Live grep", ":Telescope live_grep <CR>"),
        dashboard.button("r", "Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("q", "Quit", ":qa<CR>"),
    }

    dashboard.opts.opts.noautocmd = true

    alpha.setup(dashboard.config)
end

return M
