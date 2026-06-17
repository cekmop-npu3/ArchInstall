local M = {}

function M.setup()
    local cmp = require("cmp")
    if not cmp then
        return
    end

    cmp.setup({
        mapping = cmp.mapping.preset.insert({
            ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
            ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
            ["<Tab>"] = cmp.mapping.confirm({ select = false })
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "buffer" },
        }),
        snippet = {
            expand = function(args)
                vim.snippet.expand(args.body)
            end,
        },
        window = {
            completion = cmp.config.window.bordered({
                border = "rounded",
                max_height = 5,
                scrollbar = false,
            }),
            documentation = cmp.config.window.bordered({
                border = "rounded",
                max_height = 5,
                scrollbar = false,
            }),
        }
    })
end

return M
