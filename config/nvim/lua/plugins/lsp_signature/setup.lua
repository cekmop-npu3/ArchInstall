local M = {}

M.opts = {
    bind = true,
    always_trigger = true,
    hint_enable = false,
    floating_window = true,
    floating_window_above_cur_line = true,
    fix_pos = false,
    doc_lines = 8,
    max_height = 16,
    max_width = 80,
    close_timeout = 2500,
    handler_opts = {
        border = "rounded",
    },
}

function M.setup()
    local ok, signature = pcall(require, "lsp_signature")
    if not ok then
        return
    end

    signature.setup(M.opts)
end

function M.attach(bufnr)
    local ok, signature = pcall(require, "lsp_signature")
    if not ok then
        return
    end

    pcall(signature.on_attach, M.opts, bufnr)
end

return M
