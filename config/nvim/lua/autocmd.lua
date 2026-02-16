local bit = require("bit")


local win_bitmap = {
    netrw = 2,
    terminal = 4,
    any = 8
}


---@param buf_name string
---@return integer? 2|4|8
---@nodiscard
local function getWinBitmap(buf_name)
    local isNetrw = vim.fn.isdirectory(buf_name) == 1
    local isTerminal = buf_name:match("^term://") ~= nil
    if isNetrw then
        return win_bitmap.netrw
    elseif isTerminal then
        return win_bitmap.terminal
    else
        return win_bitmap.any
    end
end


---@param wins_count integer
---@param current_buf integer 
---@param bitmap integer
---@return nil
local function resolveWindows(wins_count, current_buf, bitmap)
    if (bitmap == bit.bor(win_bitmap.netrw, win_bitmap.any) and current_buf ~= win_bitmap.netrw and wins_count == 2)
    or (bitmap == bit.bor(win_bitmap.terminal, win_bitmap.any) and current_buf ~= win_bitmap.terminal and wins_count == 2)
    or (bitmap == bit.bor(bit.bor(win_bitmap.netrw, win_bitmap.any), win_bitmap.terminal) and current_buf == win_bitmap.any and wins_count == 3) then
        vim.cmd("new")
    end
end


---@param ev {id: number, event: string, group?: number, file: string, match: string, buf: number, data: any}
---@return nil
local function keepNetrwAlive(ev)
    local closing_win = tonumber(ev.match)
    local current_tabpage = vim.api.nvim_get_current_tabpage()
    local wins = vim.api.nvim_tabpage_list_wins(current_tabpage)
    local bitmap = 0
    WinIsPresent = false
    for _, win in ipairs(wins) do
        if win == closing_win then
            WinIsPresent = true
        end
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local b = getWinBitmap(buf_name)
        bitmap = bit.bor(bitmap, b)
    end
    if not WinIsPresent then
        return
    end
    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
    local b = getWinBitmap(current_buf_name)
    if b ~= nil and closing_win and current_buf == vim.api.nvim_win_get_buf(closing_win) then
        resolveWindows(#wins, b, bitmap)
    end
    vim.cmd("vertical wincmd =")
    vim.cmd("horizontal wincmd =")
end


vim.api.nvim_create_autocmd("WinClosed", {
    callback=keepNetrwAlive
})


local function openTerminal()
    local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage());
    NetrwActive = false
    Path = ""
    BufName = ""
    for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local b = getWinBitmap(buf_name)
        if b == win_bitmap.terminal then
            local current_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_close(win, true)
            if win ~= current_win then
                vim.api.nvim_set_current_win(current_win)
            end
            return
        elseif b == win_bitmap.netrw then
            NetrwActive = true
            Path = vim.fn.shellescape(buf_name)
            BufName = vim.fn.expand(buf_name)
        end
    end
    vim.cmd("botright 15split")
    vim.cmd("set winfixheight")
    vim.cmd("terminal")
    local current_win = vim.api.nvim_get_current_win()
    local term_job_id = vim.b.terminal_job_id
    if term_job_id then
        vim.api.nvim_chan_send(term_job_id, "cd " .. Path .. "\r")
        vim.api.nvim_chan_send(term_job_id, "clear\r")
    end
    if NetrwActive then
        vim.cmd("Lex")
        vim.cmd("Lex " .. BufName)
        vim.api.nvim_set_current_win(current_win)
    end
    vim.cmd("vertical wincmd =")
    vim.cmd("horizontal wincmd =")
end


vim.keymap.set("n", "<leader>t", openTerminal)


local function toggleNetrw()
    vim.cmd("Lex")
    vim.cmd("vertical resize 30")
    vim.cmd("vertical wincmd =")
    vim.cmd("horizontal wincmd =")
end


vim.keymap.set("n", "<leader>e",  toggleNetrw)


---@param ev {id: number, event: string, group?: number, file: string, match: string, buf: number, data: any}
---@return nil
local function handleTreeSitter(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if (not pcall(vim.treesitter.language.inspect, lang)) then
        return
    end
    vim.treesitter.start(ev.buf, vim.bo[ev.buf].filetype)
    vim.bo[ev.buf].syntax = "OFF"
end


vim.api.nvim_create_autocmd("FileType", {
    pattern = {"c", "cpp", "lua", "toml", "yml", "yaml", "md"},
    callback = handleTreeSitter,
    group = vim.api.nvim_create_augroup("NvimTreesitter", {clear = true})
})

