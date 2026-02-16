vim.lsp.config.clangd = {
    cmd = {
        'clangd',
        '--clang-tidy',
        '--background-index',
        '--offset-encoding=utf-8',
    },
    root_markers = {'.clangd',
                    'compile_commands.json',
                    'CMakeLists.txt',
                    'Makefile',
                    '.git',
                    'compile_flags.txt',
                    'build/compile_commands.json'
    },
    filetypes = {'c', 'cpp', 'ipp', 'tpp'},
    settings = {
        clangd = {
            InlayHints = {
                Enabled = true
            },
            Documentation = {
                CommentFormat = "Doxygen"
            }
        }
    }
}


vim.lsp.enable('clangd')

