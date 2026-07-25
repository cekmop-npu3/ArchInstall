local root_markers = {
    "compile_commands.json",
    "compile_flags.txt",
    "CMakePresets.json",
    "CMakeUserPresets.json",
    "CMakeLists.txt",
    ".clangd",
    "configure.ac",
    ".git",
}

local function normalize_path(path)
    return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function database_contains_file(database, source_file)
    local lines = vim.fn.readfile(database)
    local ok, entries = pcall(vim.json.decode, table.concat(lines, "\n"))

    if not ok or type(entries) ~= "table" then
        return false
    end

    local source_path = normalize_path(source_file)

    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.file) == "string" then
            local entry_file = entry.file

            if not vim.startswith(entry_file, "/") and type(entry.directory) == "string" then
                entry_file = vim.fs.joinpath(entry.directory, entry_file)
            end

            if normalize_path(entry_file) == source_path then
                return true
            end
        end
    end

    return false
end

local function newest_compile_commands(root, source_file)
    local newest_database
    local newest_time

    for _, database in ipairs(vim.fs.find("compile_commands.json", {
        path = root,
        type = "file",
        limit = math.huge,
    })) do
        if database_contains_file(database, source_file) then
            local stat = vim.uv.fs_stat(database)
            local modified = stat and stat.mtime and stat.mtime.sec

            if modified and (not newest_time or modified > newest_time) then
                newest_database = database
                newest_time = modified
            end
        end
    end

    return newest_database
end

local function start_clangd(dispatchers, config)
    local command = {
        "clangd",
        "--function-arg-placeholders=false",
    }
    local source_file = vim.api.nvim_buf_get_name(0)
    local database = config.root_dir and newest_compile_commands(config.root_dir, source_file)

    if database then
        table.insert(command, "--compile-commands-dir=" .. vim.fs.dirname(database))
    end

    return vim.lsp.rpc.start(command, dispatchers, {
        cwd = config.root_dir,
    })
end

local function config(filetypes, fallback_flags)
    return {
        cmd = start_clangd,
        filetypes = filetypes,
        root_markers = root_markers,
        init_options = {
            fallbackFlags = fallback_flags,
        },
    }
end

return {
    c = config({ "c", "c.doxygen" }, { "-std=c23" }),
    cpp = config({ "cpp", "cpp.doxygen" }, { "-std=c++23" }),
}
