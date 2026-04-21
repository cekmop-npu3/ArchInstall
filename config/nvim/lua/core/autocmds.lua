
local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("core_autocmds", { clear = true })

    vim.api.nvim_create_autocmd("TextYankPost", {
        group = group,
        callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "diff",
        callback = function()
            vim.opt_local.foldenable = false
        end,
    })
end

return M
