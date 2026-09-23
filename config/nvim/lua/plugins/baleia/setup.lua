local M = {}

function M.setup()
    local baleia = require("baleia").setup({
        async = false,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "git",
        callback = function()
            baleia.once(vim.api.nvim_get_current_buf())
            vim.bo.modified = false
        end,
    })
end

return M
