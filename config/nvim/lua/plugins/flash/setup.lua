local M = {}

function M.setup()
    local ok, flash = pcall(require, "flash")
    if not ok then
        return
    end
    flash.setup({
        search = {
            multi_window = false
        },
        modes = {
            char = {
                jump_labels = true
            }
        },
        remote = {
            remote_op = {
                restore = true,
                motion = true
            }
        }
    })

    require("plugins.flash.keymaps").setup()
end

return M

