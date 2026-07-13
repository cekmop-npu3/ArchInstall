local M = {}
local previous_win
local completion_win

local function documentation_window()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "cmp_docs" then
            return win
        end
    end
end

local function detach_documentation_window(docs_win)
    local ok, cmp = pcall(require, "cmp")
    if not ok then
        return
    end

    local docs_view = cmp.core and cmp.core.view and cmp.core.view.docs_view
    local window = docs_view and docs_view.window
    if not window or window.win ~= docs_win then
        return
    end

    for _, field in ipairs({ "sbar_win", "thumb_win" }) do
        local win = window[field]
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_hide(win)
        end
        window[field] = nil
    end

    window.win = nil
end

local function set_documentation_mapping(docs_win)
    local docs_buf = vim.api.nvim_win_get_buf(docs_win)
    vim.keymap.set({ "n", "i", "s" }, "<M-p>", function()
        M.toggle_documentation_focus(function() end)
    end, {
        buffer = docs_buf,
        silent = true,
        desc = "Return from CMP documentation",
    })
end

local function copy_documentation_buffer(docs_win)
    local source_buf = vim.api.nvim_win_get_buf(docs_win)
    local docs_buf = vim.api.nvim_create_buf(false, true)
    local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)

    vim.api.nvim_buf_set_lines(docs_buf, 0, -1, false, lines)
    vim.bo[docs_buf].filetype = "cmp_docs"
    vim.bo[docs_buf].bufhidden = "wipe"
    vim.api.nvim_win_set_buf(docs_win, docs_buf)

    return docs_buf
end

function M.setup(cmp)
    cmp.event:on("menu_opened", function()
        completion_win = vim.api.nvim_get_current_win()
    end)
end

function M.toggle_documentation_focus(fallback)
    local docs_win = documentation_window()
    if not docs_win then
        fallback()
        return
    end

    local current_win = vim.api.nvim_get_current_win()
    if current_win == docs_win then
        if previous_win and vim.api.nvim_win_is_valid(previous_win) then
            vim.api.nvim_set_current_win(previous_win)
        else
            vim.cmd("wincmd p")
        end
        if vim.api.nvim_win_is_valid(docs_win) then
            vim.api.nvim_win_close(docs_win, true)
        end
        previous_win = nil
        return
    end

    if completion_win and vim.api.nvim_win_is_valid(completion_win) then
        previous_win = completion_win
    else
        previous_win = current_win
    end

    vim.api.nvim_win_set_height(docs_win, 15)
    detach_documentation_window(docs_win)
    local docs_buf = copy_documentation_buffer(docs_win)
    set_documentation_mapping(docs_win)
    vim.bo[docs_buf].modifiable = false
    vim.api.nvim_set_current_win(docs_win)
    vim.cmd("stopinsert")
end

return M
