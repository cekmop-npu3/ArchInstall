return {
    cmd = { "pyrefly", "lsp" },
    filetypes = { "python" },
    root_markers = {
        "pyrefly.toml",
        "pyproject.toml",
        "pyrightconfig.json",
        "mypy.ini",
        ".git",
    },
    settings = {
        python = {
            pyrefly = {
                typeCheckingMode = "strict",
                disableTypeErrors = false,
                disableLanguageServices = false,
            },
            analysis = {
                diagnosticMode = "workspace",
                importFormat = "absolute",
                showHoverGoToLinks = true,
                inlayHints = {
                    callArgumentNames = "partial",
                    functionReturnTypes = true,
                    variableTypes = true,
                    pytestParameters = true,
                },
            },
        },
    },
}
