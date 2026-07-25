local M = {}

function M.setup()
    local ok_bufferline, bufferline = pcall(require, "bufferline")
    if not ok_bufferline then
        return
    end

    bufferline.setup({
        options = {
            mode = "tabs",
            separator_style = "thick",
            always_show_bufferline = false,
            show_buffer_close_icons = false,
            show_close_icon = false,
            diagnostics = false,
        }
    })
end

return M
