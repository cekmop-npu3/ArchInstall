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

local function path_is_inside(path, root)
    path = normalize_path(path)
    root = normalize_path(root)

    return path == root or vim.startswith(path, root .. "/")
end

local function decode_database(database)
    local lines = vim.fn.readfile(database)
    local ok, entries = pcall(vim.json.decode, table.concat(lines, "\n"))

    if not ok or type(entries) ~= "table" then
        return nil
    end

    return entries
end

local function entry_file_path(entry)
    if type(entry) ~= "table" or type(entry.file) ~= "string" then
        return nil
    end

    local entry_file = entry.file

    if not vim.startswith(entry_file, "/") and type(entry.directory) == "string" then
        entry_file = vim.fs.joinpath(entry.directory, entry_file)
    end

    return normalize_path(entry_file)
end

local function database_contains_file(entries, source_file)
    if not entries then
        return false
    end

    local source_path = normalize_path(source_file)

    for _, entry in ipairs(entries) do
        if entry_file_path(entry) == source_path then
            return true
        end
    end

    return false
end

local function cmake_cache_source_dir(build_dir)
    local cache = vim.fs.joinpath(build_dir, "CMakeCache.txt")

    if vim.uv.fs_stat(cache) == nil then
        return nil
    end

    for _, line in ipairs(vim.fn.readfile(cache)) do
        local source_dir = line:match("^CMAKE_HOME_DIRECTORY:INTERNAL=(.+)$")

        if source_dir then
            return normalize_path(source_dir)
        end
    end

    return nil
end

local function database_is_in_project_build_dir(database, root)
    local relative = vim.fs.relpath(normalize_path(root), normalize_path(vim.fs.dirname(database)))

    if not relative then
        return false
    end

    if relative == "." then
        return true
    end

    local first_part = relative:match("^([^/]+)")

    return first_part == "build"
        or first_part == "bin"
        or vim.startswith(first_part, "cmake-build-")
        or first_part == "out"
end

local function database_belongs_to_root(database, root, entries)
    local database_dir = vim.fs.dirname(database)
    local cache_source_dir = cmake_cache_source_dir(database_dir)
    local normalized_root = normalize_path(root)

    if cache_source_dir then
        return cache_source_dir == normalized_root
    end

    if not path_is_inside(database, normalized_root) then
        return false
    end

    if not database_is_in_project_build_dir(database, normalized_root) then
        return false
    end

    for _, entry in ipairs(entries or {}) do
        local file = entry_file_path(entry)

        if file and path_is_inside(file, normalized_root) then
            return true
        end
    end

    return false
end

local function newest_compile_commands(root, source_file)
    local exact_database
    local exact_time
    local newest_database
    local newest_time

    for _, database in ipairs(vim.fs.find("compile_commands.json", {
        path = root,
        type = "file",
        limit = math.huge,
    })) do
        local entries = decode_database(database)

        if entries and database_belongs_to_root(database, root, entries) then
            local stat = vim.uv.fs_stat(database)
            local modified = stat and stat.mtime and stat.mtime.sec

            if modified and database_contains_file(entries, source_file) and (not exact_time or modified > exact_time) then
                exact_database = database
                exact_time = modified
            end

            if modified and (not newest_time or modified > newest_time) then
                newest_database = database
                newest_time = modified
            end
        end
    end

    return exact_database or newest_database
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

