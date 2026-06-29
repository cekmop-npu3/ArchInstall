local M = {}

function M.setup()
    local ok_noice, noice = pcall(require, "noice")
    if not ok_noice then
        return
    end

    local popup_winhighlight = {
        Normal = "PopupMenuBody",
        NormalFloat = "PopupMenuBody",
        FloatBorder = "PopupMenuBorder",
    }

    noice.setup({
        views = {
            popup = {
                win_options = {
                    winhighlight = popup_winhighlight,
                },
            },
            hover = {
                relative = "cursor",
                anchor = "SW",
                position = { row = 0, col = 4 },
                scrollbar = false,
                size = { width = "50%", height = "30%" },
                win_options = {
                    winhighlight = popup_winhighlight,
                },
            },
        },
        lsp = {
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
        },
        presets = {
            command_palette = true,
            long_message_to_split = true,
            lsp_doc_border = true,
        },
        messages = {
            enabled = false
        }
    })

    require("plugins.noice.keymaps").setup()
end

return M
