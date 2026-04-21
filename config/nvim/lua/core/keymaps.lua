local M = {}

function M.setup()
    vim.keymap.set("n", "K", "H", { desc = "Cursor to screen top" })
    vim.keymap.set("n", "J", "L", { desc = "Cursor to screen bottom" })
    vim.keymap.set({ "n", "v" }, "<leader>k", "gg", { desc = "Go to file start" })
    vim.keymap.set({ "n", "v" }, "<leader>j", "G", { desc = "Go to file end" })
    vim.keymap.set("n", "<leader><Tab>", ":tabn<CR>", { desc = "Next tab" })
    vim.keymap.set("n", "<leader><S-Tab>", ":tabp<CR>", { desc = "Previous tab" })
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

    vim.keymap.set("n", "<A-h>", "<C-w>h", { remap = true, silent = true, desc = "Window left" })
    vim.keymap.set("n", "<A-j>", "<C-w>j", { remap = true, silent = true, desc = "Window down" })
    vim.keymap.set("n", "<A-k>", "<C-w>k", { remap = true, silent = true, desc = "Window up" })
    vim.keymap.set("n", "<A-l>", "<C-w>l", { remap = true, silent = true, desc = "Window right" })

    vim.keymap.set("n", "<A-p>", "<C-w>p", { remap = true, silent = true, desc = "Previous window" })
    vim.keymap.set("n", "<A-c>", "<C-w>c", { remap = true, silent = true, desc = "Close window" })
    vim.keymap.set("n", "<A-o>", "<C-w>o", { remap = true, silent = true, desc = "Only window" })

    vim.keymap.set("n", "<A-v>", "<C-w>v", { remap = true, silent = true, desc = "Vertical split" })
    vim.keymap.set("n", "<A-V>", "<C-w>s", { remap = true, silent = true, desc = "Horizontal split" })

    vim.keymap.set("n", "<A-H>", "<C-w>H", { remap = true, silent = true, desc = "Move window far left" })
    vim.keymap.set("n", "<A-J>", "<C-w>J", { remap = true, silent = true, desc = "Move window far down" })
    vim.keymap.set("n", "<A-K>", "<C-w>K", { remap = true, silent = true, desc = "Move window far up" })
    vim.keymap.set("n", "<A-L>", "<C-w>L", { remap = true, silent = true, desc = "Move window far right" })

    vim.keymap.set("n", "<A-r>", "<C-w>r", { remap = true, silent = true, desc = "Rotate windows forward" })
    vim.keymap.set("n", "<A-R>", "<C-w>R", { remap = true, silent = true, desc = "Rotate windows backward" })
    vim.keymap.set("n", "<A-t>", "<C-w>T", { remap = true, silent = true, desc = "Window to new tab" })

    vim.keymap.set("n", "<A-=>", "<C-w>+", { remap = true, silent = true, desc = "Increase window height" })
    vim.keymap.set("n", "<A-->", "<C-w>-", { remap = true, silent = true, desc = "Decrease window height" })
    vim.keymap.set("n", "<A-,>", "<C-w><", { remap = true, silent = true, desc = "Decrease window width" })
    vim.keymap.set("n", "<A-.>", "<C-w>>", { remap = true, silent = true, desc = "Increase window width" })

    vim.keymap.set("n", "<leader>m", function()
        ---@diagnostic disable-next-line
        local mark = vim.fn.nr2char(vim.fn.getchar())
        if mark:match("[a-zA-Z]") then
            vim.cmd("normal! `" .. mark)
        end
    end, { desc = "Jump to mark by letter" })

    vim.keymap.set("n", "<leader>q", function()
        ---@diagnostic disable-next-line
        local reg = vim.fn.nr2char(vim.fn.getchar())
        if reg:match("[a-zA-Z]") then
            vim.cmd("normal! @" .. reg)
        end
    end, { desc = "Run macro by register" })

    vim.keymap.set("n", "zr", "zO", { remap = true, desc = "Open folds recursively" })
    vim.keymap.set("n", "zc", "zC", { remap = true, desc = "Close folds recursively" })
    vim.keymap.set("n", "zE", "zD", { remap = true, desc = "Delete folds in cursor line" })

end

return M
