
local M = {}

function M.safe_setup(mod, opts)
    opts = opts or {}

    local ok_require, module_or_err = pcall(require, mod)
    if not ok_require then
        if opts.optional and type(module_or_err) == "string" and module_or_err:match("module '" .. mod .. "' not found") then
            return nil
        end

        vim.notify(("Failed loading %s: %s"):format(mod, module_or_err), vim.log.levels.WARN)
        return nil
    end

    local module = module_or_err
    if not module then
        return nil
    end

    if type(module.setup) ~= "function" then
        vim.notify(("Module %s does not export setup()")
            :format(mod), vim.log.levels.WARN)
        return module
    end

    local ok, err = pcall(module.setup)
    if not ok then
        vim.notify(("Failed setup %s: %s"):format(mod, err), vim.log.levels.WARN)
    end

    return module
end

return M
