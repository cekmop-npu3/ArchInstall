local M = {}

---@param original_preview function
---@param contents table
---@param syntax string
---@param opts vim.lsp.util.open_floating_preview.Opts?
function M.modified_preview(original_preview, contents, syntax, opts)
    -- Keep Python-specific LSP preview changes here.
    return original_preview(contents, syntax, opts)
end

return M

