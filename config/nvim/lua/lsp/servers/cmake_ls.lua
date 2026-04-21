
local M = {}

function M.setup()
    local neocmake = vim.fn.exepath("neocmakelsp")
    local cmd = neocmake ~= "" and { neocmake, "--stdio" } or { "neocmakelsp", "--stdio" }

    vim.lsp.config.cmakels = {
        cmd = cmd,
        filetypes = { "cmake" },
        root_markers = { "CMakeLists.txt" },
        init_options = {
            format = {
                enable = true,
            },
            lint = {
                enable = true,
            },
        },
    }
end

return M
