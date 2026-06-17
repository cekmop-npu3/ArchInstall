local M = {}

local function escape_path_for_grug_far(path)
    local escaped = path:gsub(" ", "\\ ")
    return escaped
end

local function grug_far_paths()
    local paths = {}
    local seen = {}

    local function add(path)
        if not path or path == "" then
            return
        end

        local normalized = vim.fn.fnamemodify(path, ":p")
        if seen[normalized] then
            return
        end

        seen[normalized] = true
        table.insert(paths, escape_path_for_grug_far(normalized))
    end

    add(vim.fn.getcwd())

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= "" then
                add(vim.fn.fnamemodify(name, ":p:h"))
            end
        end
    end

    return table.concat(paths, "\n")
end

function M.setup()
    local ok, grug = pcall(require, "grug-far")
    if not ok then
        return
    end

    vim.keymap.set("n", "<leader>fr", function()
        grug.open({
            prefills = {
                paths = grug_far_paths(),
            },
        })
    end, { desc = "Grug Far" })
end

return M
