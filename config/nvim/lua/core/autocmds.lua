local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "diff",
        callback = function()
            vim.opt_local.foldenable = false
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "cmake",
        callback = function()
            vim.opt_local.expandtab = true
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.softtabstop = 2
        end,
    })
end

return M
