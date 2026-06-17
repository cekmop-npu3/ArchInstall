local M = {}

local function get_hl(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
    if ok then
        return hl
    end

    return {}
end

local function set_popup_highlights()
    local body = get_hl("Normal")
    if not body.bg then
        body = get_hl("NormalFloat")
    end
    if not body.bg then
        body = get_hl("Pmenu")
    end

    local border = get_hl("FloatBorder")

    if body.bg then
        vim.api.nvim_set_hl(0, "PopupMenuBody", {
            bg = body.bg,
            fg = body.fg,
        })
    end

    vim.api.nvim_set_hl(0, "PopupMenuBorder", {
        fg = border.fg,
        bg = body.bg,
    })
end

function M.setup()
    local group = vim.api.nvim_create_augroup("PopupThemeHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = set_popup_highlights,
    })

    set_popup_highlights()
end

return M
