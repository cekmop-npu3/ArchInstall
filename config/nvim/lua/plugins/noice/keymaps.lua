local M = {}
local previous_win

function M.setup()
    vim.keymap.set({ "n", "i", "s" }, "<M-p>", function()
        local docs = require("noice.lsp.docs")
        local current_win = vim.api.nvim_get_current_win()
        local signature_win = docs.get("signature"):win()
        local hover_win = docs.get("hover"):win()

        if current_win == signature_win or current_win == hover_win then
            if previous_win and vim.api.nvim_win_is_valid(previous_win) then
                vim.api.nvim_set_current_win(previous_win)
            else
                vim.cmd("wincmd p")
            end
            return
        end

        previous_win = current_win
        if not docs.get("signature"):focus() then
            docs.get("hover"):focus()
        end
    end, { desc = "Toggle Noice LSP popup focus" })
end

return M
