
local M = {}

function M.setup()
    vim.g.mapleader = " "
    vim.g.loaded_netrwPlugin = 1

    vim.o.showmode = true
    vim.o.scrolloff = 3
    vim.o.matchpairs = "(:),{:},[:],<:>"
    vim.o.number = true
    vim.o.ruler = true
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
    vim.o.softtabstop = 4
    vim.o.expandtab = true
    vim.o.swapfile = false
    vim.o.relativenumber = true
    vim.o.autoindent = true
    vim.o.smartindent = true
    vim.o.clipboard = "unnamedplus"
    vim.o.completeopt = "menu,menuone,noselect"
    vim.o.autocomplete = false
    vim.o.smartcase = true
    vim.o.splitright = true
    vim.o.splitbelow = true
    vim.o.termguicolors = true
    vim.o.confirm = true
    vim.o.wrap = true

    vim.g.netrw_browse_split = 0
    vim.g.netrw_banner = 0
    vim.g.netrw_liststyle = 3
end

return M
