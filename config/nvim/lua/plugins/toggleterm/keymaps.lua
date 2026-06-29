local M = {}

---@param toggle_function fun(count: number?, size: number?, dir: string?, direction: string?, name: string?)
function M.setup(toggle_function)
    vim.keymap.set("n", "<leader>t", function ()
        toggle_function(nil, 15)
    end
)
end

return M
