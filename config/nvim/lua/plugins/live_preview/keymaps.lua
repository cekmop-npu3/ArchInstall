local M = {}

local is_open = false

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
            vim.keymap.set("n", "<leader>mp", function()
                if is_open then
                    vim.cmd("LivePreview close")
                else
                    vim.cmd("LivePreview start")
                end

                is_open = not is_open
            end, {
                buffer = ev.buf,
                desc = "Toggle Markdown preview",
            })
        end,
    })
end

return M
