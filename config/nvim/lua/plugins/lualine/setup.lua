local M = {}

function M.setup()
    local ok_lualine, lualine = pcall(require, "lualine")
    if not ok_lualine then
        return
    end

    local function show_macro_recording()
        local recording_register = vim.fn.reg_recording()
        if recording_register == "" then
            return ""
        else
            return "Recording @" .. recording_register
        end
    end

    lualine.setup({
        options = {
            theme = "auto",
            globalstatus = true,
            disabled_filetypes = {
                statusline = { "alpha", "dashboard" },
            },
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = {
                {
                    show_macro_recording,
                    color = { fg = "#ff9e64" },
                },
                {
                    "filename",
                    path = 1,
                },
            },
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {
                {
                    "filename",
                    path = 1,
                },
            },
            lualine_x = { "location" },
            lualine_y = {},
            lualine_z = {},
        },
    })
end

return M
