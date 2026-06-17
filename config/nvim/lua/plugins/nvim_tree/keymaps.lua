local M = {}

function M.on_attach(bufnr)
    local api = require("nvim-tree.api")
    api.map.on_attach.default(bufnr)

    local function opts(desc)
        return {
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
            desc = "nvim-tree: " .. desc,
        }
    end

    vim.keymap.set("n", "<C-h>", api.node.open.horizontal, opts("Open: Horizontal Split"))
    vim.keymap.set("n", "rb", api.fs.rename_basename, opts("Rename: Basename"))
    vim.keymap.set("n", "rp", api.fs.rename_full, opts("Rename: Full Path"))
    vim.keymap.set("n", ".", api.filter.dotfiles.toggle, opts("Toggle Filter: Dotfiles"))
    vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
    vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
    vim.keymap.del("n", "<C-k>", { buffer = bufnr })
end

function M.setup()
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
end

return M
