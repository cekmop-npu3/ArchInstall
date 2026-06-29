local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
            vim.keymap.set("n", "<leader>mr", function()
                require("render-markdown").toggle()
            end, {
                buffer = ev.buf,
                desc = "Toggle render-markdown",
            })
        end,
    })
end

return M
