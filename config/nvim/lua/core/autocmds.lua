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
end

return M
