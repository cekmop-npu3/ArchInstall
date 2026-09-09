local M = {}

local original_preview = vim.lsp.util.open_floating_preview
local language_previews = {
    python = require("lsp.config.python.preview"),
}

function M.setup()
    vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
        local preview = language_previews[vim.bo.filetype]
        if preview then
            return preview.modified_preview(original_preview, contents, syntax, opts)
        end

        return original_preview(contents, syntax, opts)
    end
end

return M
