return {
    cmd = { "neocmakelsp", "stdio" },
    filetypes = { "cmake" },
    init_options = {
        format = {
            enable = true,
        },
        lint = {
            enable = true,
        },
        scan_cmake_in_package = true,
    },
}
