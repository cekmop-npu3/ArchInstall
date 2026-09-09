local M = {}

function M.setup()
    local ok, lsp_signature = pcall(require, "lsp_signature")
    if not ok then
        return
    end
    lsp_signature.setup({
        doc_lines = 0,
        floating_window = false,
        hint_prefix = {
            above = "↙ ",
            current = "← ",
            below = "↖ "
        }
    })
end

return M

