vim.lsp.config["cmakels"] = {
    cmd = {"/home/cekmop-npu3/.cargo/bin/neocmakelsp", "--stdio"},
    filetypes = {"cmake"},
    root_markers = {"CMakeLists.txt"},
    init_options = {
        format = {
            enable = true
        },
        lint = {
            enable = true
        }
    }
}

vim.lsp.enable("cmakels")

