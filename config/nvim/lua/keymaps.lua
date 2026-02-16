vim.keymap.set("n", "K", "H")
vim.keymap.set("n", "J", "L")
vim.keymap.set("n", "<leader>k", "gg")
vim.keymap.set("n", "<leader>j", "G")
vim.keymap.set("n", "<leader><Tab>", ":tabn<CR>")
vim.keymap.set("n", "<leader><S-Tab>", ":tabp<CR>")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set('n', '<leader>d', vim.lsp.buf.hover)
vim.keymap.set('i', '<C-space>', vim.lsp.buf.signature_help)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<C-w><", "<C-w>5>")
vim.keymap.set("n", "<C-w>>", "<C-w>5<")
vim.keymap.set("n", "<C-w>-", "<C-w>5-")
vim.keymap.set("n", "<C-w>=", "<C-w>5=")
vim.keymap.set("n", "<leader>m", function ()
    if (vim.bo.filetype == "markdown") then
        vim.cmd("MarkdownPreview")
    end
end
)
vim.keymap.set("n", "<leader>sm", function ()
    if (vim.bo.filetype == "markdown") then
        vim.cmd("MarkdownPreviewStop")
    end
end
)



---@param keymap string
---@param pass string
---@return string
local function setSuggestionKeymap(keymap, pass)
    if vim.fn.pumvisible() == 1 then
        return keymap
    end
    return pass
end


---@param direction string
---@alias direction "down" | "up"
---@return string
local function paginateDirection(direction)
    if direction == "down" then
        return setSuggestionKeymap("<C-j>", "<C-n>")
    end
    return setSuggestionKeymap("<C-k>", "<C-p>")
end


vim.keymap.set("i", "<C-j>", paginateDirection("down"))
vim.keymap.set("i", "<C-k>", paginateDirection("up"))


local gitSigns = require("gitsigns")


local function gitBlameOnVisual()
    local startLine = vim.fn.line("'<")
    local endLine = vim.fn.line(">'")
    if startLine > endLine then
       startLine, endLine = endLine, startLine
    end
    gitSigns.blame_line({full=true, ignore_whitespace=true, line_start=startLine, line_end=endLine})
end


vim.keymap.set("n", "<leader>gb", gitSigns.toggle_current_line_blame)
vim.keymap.set("n", "<leader>lt", gitSigns.toggle_signs)
vim.keymap.set("v", "<leader>gb", gitBlameOnVisual)

