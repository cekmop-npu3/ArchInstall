local M = {}

function M.setup()
    local ok, render_markdown = pcall(require, "render-markdown")
    if not ok then
        return
    end

    render_markdown.setup({
        completions = {
            lsp = {
                enabled = true,
            },
        },

        file_types = {
            "markdown"
        },

        heading = {
            icons = {
                "",
                "",
                "",
                "",
                "",
                "",
            },
        },

        bullet = {
            icons = {
                "• ",
                "• ",
                "• ",
            },
        },

        overrides = {
            buftype = {
                nofile = {
                    render_modes = true,
                },
            },
        },
    })

    require("plugins.render_markdown.keymaps").setup()
end

return M

