#Requires -Version 5.1

<#
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
#>

param([switch]$SkipFont)

$ErrorActionPreference = 'Stop'

function Update-SessionPath {
    $paths = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $env:Path
    $env:Path = (($paths -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';')
}

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command $($Arguments -join ' ') failed (exit $LASTEXITCODE)."
    }
}

function Add-UserPath {
    param([string]$Directory)
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $Directory) {
        [Environment]::SetEnvironmentVariable('Path', "$Directory;$userPath", 'User')
    }
    Update-SessionPath
}

function Install-WingetPackage {
    param([string]$Id, [string[]]$ExtraArguments = @())
    & winget install --id $Id --exact --source winget --silent --architecture x64 `
        --accept-package-agreements --accept-source-agreements @ExtraArguments
    # WinGet returns this code when the installed package is already current.
    if ($LASTEXITCODE -notin @(0, -1978335189)) {
        throw "WinGet failed installing $Id (exit $LASTEXITCODE)."
    }
    Update-SessionPath
}

try {
    if ($env:OS -ne 'Windows_NT') {
        throw 'Run this script on Windows. Use setup.sh for Linux.'
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'Install or update Microsoft App Installer (WinGet), then rerun: https://aka.ms/getwinget'
    }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw 'This script requires x64 Windows and a 64-bit PowerShell session.'
    }

    # WinLibs supplies GCC and its runtime; LLVM supplies clangd.
    $packages = @(
        'Neovim.Neovim', 'Git.Git', 'BurntSushi.ripgrep.MSVC',
        'BrechtSanders.WinLibs.POSIX.UCRT', 'LLVM.LLVM',
        'OpenJS.NodeJS.LTS', 'astral-sh.uv', 'Kitware.CMake',
        'LuaLS.lua-language-server'
    )
    if (-not $SkipFont) { $packages += 'DEVCOM.JetBrainsMonoNerdFont' }
    foreach ($package in $packages) {
        Install-WingetPackage $package
    }

    # LLVM's silent installer does not always add its bin directory to PATH.
    $llvmBin = Join-Path $env:ProgramFiles 'LLVM\bin'
    if (Test-Path (Join-Path $llvmBin 'clangd.exe')) { Add-UserPath $llvmBin }

    # Use the GNU Rust toolchain to build neocmakelsp with WinLibs.
    if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
        Install-WingetPackage 'Rustlang.Rustup' @('--override',
            '-y --default-toolchain stable-x86_64-pc-windows-gnu --profile minimal')
    }
    $cargoDir = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $env:USERPROFILE '.cargo' }
    Add-UserPath (Join-Path $cargoDir 'bin')
    Invoke-Checked 'rustup' @('toolchain', 'install', 'stable-x86_64-pc-windows-gnu', '--profile', 'minimal')
    Invoke-Checked 'cargo' @('+stable-x86_64-pc-windows-gnu', 'install', '--locked', 'neocmakelsp')

    Invoke-Checked 'npm.cmd' @('install', '--global', 'bash-language-server', 'tree-sitter-cli')
    $npmBin = & npm.cmd prefix --global
    if ($LASTEXITCODE -ne 0) { throw 'Could not locate npm global executables.' }
    Add-UserPath ($npmBin | Select-Object -Last 1)

    Invoke-Checked 'uv' @('python', 'install', '3.13', '--default')
    Invoke-Checked 'uv' @('python', 'update-shell')
    Update-SessionPath
    Invoke-Checked 'uv' @('tool', 'install', '--python', '3.13', 'pyrefly')
    $uvBin = & uv tool dir --bin
    if ($LASTEXITCODE -ne 0) { throw 'Could not locate uv tool executables.' }
    Add-UserPath ($uvBin | Select-Object -Last 1)

    foreach ($command in @(
        'nvim', 'git', 'rg', 'gcc', 'clangd', 'tree-sitter', 'curl.exe', 'tar.exe',
        'node', 'python', 'cmake', 'lua-language-server', 'neocmakelsp',
        'bash-language-server', 'pyrefly'
    )) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Missing command after installation: $command"
        }
    }
    Invoke-Checked 'nvim' @('--headless', '-u', 'NONE', '-i', 'NONE',
        '+lua local v = vim.version(); if v.major == 0 and v.minor < 12 then os.exit(1) end', '+qa')

    Write-Host "Dependencies installed. Restart your terminal to refresh PATH."
    Write-Host "Place init.lua and lua/ in $env:LOCALAPPDATA\nvim, then start nvim to install plugins."
    if (-not $SkipFont) {
        Write-Host 'Select JetBrainsMono Nerd Font in your terminal settings.'
    }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}

