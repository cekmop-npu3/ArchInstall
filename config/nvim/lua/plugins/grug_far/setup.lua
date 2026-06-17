local M = {}

function M.setup()
    local ok, grug = pcall(require, "grug-far")
    if not ok then
        return
    end

    grug.setup({
        keymaps = {
            replace = { n = "<leader>r" },
        },
    })

    require("plugins.grug_far.keymaps").setup()
end

return M
