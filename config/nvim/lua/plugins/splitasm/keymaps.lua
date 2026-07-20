local M = {}

local project_markers = {
    {
        ".git",
        "CMakeLists.txt",
        "Makefile",
        "meson.build",
        "configure.ac",
    },
}

local function absolute(path, directory)
    if vim.startswith(path, "/") then
        return vim.fs.normalize(path)
    end

    return vim.fs.normalize(vim.fs.joinpath(directory, path))
end

local function compilation_for(source)
    local root = vim.fs.root(source, project_markers) or vim.fs.dirname(source)
    local databases = vim.fs.find("compile_commands.json", {
        path = root,
        type = "file",
        limit = math.huge,
    })

    for _, database in ipairs(databases) do
        local ok, entries = pcall(function()
            return vim.json.decode(table.concat(vim.fn.readfile(database), "\n"))
        end)

        if ok then
            for _, entry in ipairs(entries) do
                if absolute(entry.file, entry.directory) == source then
                    if not entry.output then
                        return nil, "The compilation database entry does not specify its output object."
                    end

                    local directory = vim.fs.dirname(database)
                    local command

                    if vim.fn.filereadable(vim.fs.joinpath(directory, "CMakeCache.txt")) == 1 then
                        command = "cmake --build " .. vim.fn.shellescape(directory)
                    elseif vim.fn.filereadable(vim.fs.joinpath(directory, "build.ninja")) == 1 then
                        command = "ninja -C " .. vim.fn.shellescape(directory)
                    elseif vim.fn.filereadable(vim.fs.joinpath(directory, "Makefile")) == 1 then
                        command = "make -C " .. vim.fn.shellescape(directory)
                    elseif entry.command then
                        command = "cd " .. vim.fn.shellescape(entry.directory) .. " && " .. entry.command
                    else
                        command = table.concat(vim.tbl_map(vim.fn.shellescape, entry.arguments), " ")
                    end

                    return {
                        command = command,
                        object = absolute(entry.output, entry.directory),
                    }
                end
            end
        end
    end

    if #databases == 0 then
        return nil, "No compile_commands.json exists under " .. root
    end

    return nil, "The compilation databases under " .. root .. " do not contain the current file."
end

local function open_assembly()
    vim.cmd.update()

    local compilation, err = compilation_for(vim.fs.normalize(vim.api.nvim_buf_get_name(0)))
    if not compilation then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end

    require("splitasm").setup({
        compiler_cmd = compilation.command,
        executable_path = compilation.object,
        auto_sync = true,
        hide_address = false,
        source_row_colors = true,
        show_line_numbers = true,
    })

    vim.wo.cursorline = true

    vim.api.nvim_create_autocmd("WinNew", {
        group = vim.api.nvim_create_augroup("SplitAsmDirection", { clear = true }),
        once = true,
        callback = function()
            vim.schedule(function()
                vim.wo.cursorline = true
            end)
        end,
    })

    vim.cmd.SplitAsmOpen(compilation.object)
end

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "c",
        callback = function(event)
            vim.keymap.set("n", "<leader>as", open_assembly, {
                buffer = event.buf,
                desc = "Compile and open synchronized assembly",
            })
        end,
    })
end

return M
