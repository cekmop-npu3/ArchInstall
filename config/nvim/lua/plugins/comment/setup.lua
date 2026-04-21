
local M = {}


local comment_specs = {
    java = { "//%s", "/*%s*/" },
    go = { "//%s", "/*%s*/" },
    python = { "#%s", "\"\"\"%s\"\"\"" },
    c = { "//%s", "/*%s*/" },
    cpp = { "//%s", "/*%s*/" },
    lua = { "--%s", "--[[%s]]" },
    bash = { "#%s", ": ' %s '" },
    sh = { "#%s", ": ' %s '" },
}

function M.setup()
    local comment_ft = require("Comment.ft")
    local comment_utils = require("Comment.utils")
    local comment = require("Comment")
    if not comment_ft or not comment_utils or not comment then
        return
    end

    for lang, spec in pairs(comment_specs) do
        comment_ft.set(lang, spec)
    end

    comment.setup({
        mappings = {
            basic = false,
            extra = false,
        },
        pre_hook = function(ctx)
            local ft = vim.bo.filetype
            local base_ft = ft:match("^[^%.]+") or ft
            local spec = comment_specs[ft] or comment_specs[base_ft]
            if not spec then
                return nil
            end
            if ctx.ctype == comment_utils.ctype.blockwise then
                return spec[2]
            end
            return spec[1]
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java", "go", "python", "c", "cpp", "lua", "bash", "sh" },
        callback = function(ev)
            local ft = vim.bo[ev.buf].filetype
            local spec = comment_specs[ft]
            if spec then
                vim.bo[ev.buf].commentstring = spec[1]
            end
        end,
    })
end

return M
