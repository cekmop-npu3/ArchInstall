local M = {}

function M.setup()
    local ok, ufo = pcall(require, "ufo")
    if not ok then
        return
    end

    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    ufo.setup({
        provider_selector = function(_, _, _)
            return { "lsp", "indent" }
        end,
    })
end

return M
