
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
            ["<C-n>"] = cmp.mapping(function()
                cmp.scroll_docs(4)
            end, { "i", "c" }),
            ["<C-p>"] = cmp.mapping(function()
                cmp.scroll_docs(-4)
            end, { "i", "c" }),
            ["<Tab>"] = cmp.mapping.confirm({ select = false }),
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "buffer" },
        }),
        window = {
            completion = cmp.config.window.bordered({
                scrollbar = false,
                max_height = 5,
                max_width = 60,
                winblend = 0,
            }),
            documentation = cmp.config.window.bordered({
                scrollbar = false,
                max_width = 60,
                max_height = 20,
                col_offset = 1,
            }),
        },
        snippet = {
            expand = function(args)
                vim.snippet.expand(args.body)
            end,
        },
    })
end

return M
