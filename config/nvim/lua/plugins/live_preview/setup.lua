local M = {}

function M.setup()
    local ok, livepreview_config = pcall(require, "livepreview.config")
    if not ok then
        return
    end

    livepreview_config.set({})

    require("plugins.live_preview.keymaps").setup()
end

return M
