
local M = {}


function M.setup()
    local java = require("java")
    if not java then
        return
    end

    java.setup()
end

return M
