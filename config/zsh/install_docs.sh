#!/usr/bin/bash

declare PASSWORD=""
read -t 0 && read -r PASSWORD

function mirror_cplusplus () {
    local url="$1"
    local marker_path="$2"

    wget --mirror --convert-links --adjust-extension --page-requisites --no-parent \
        --domains=cplusplus.com --waitretry=5 --tries=5 --timeout=30 \
        --retry-on-http-error=429,500,502,503,504 \
        --directory-prefix="$HOME/.local/share/doc/C++/cplusplus" \
        "$url"
    local wget_status=$?

    # Exit status 8 means one or more linked resources returned an HTTP error.
    # The CPlusPlus documentation pages are still mirrored and link-converted.
    (( wget_status == 0 || wget_status == 8 )) || return "$wget_status"
    touch "$marker_path"
}

function main () {
    mkdir -p ~/.local/share/doc/C ~/.local/share/doc/C++
    [[ -f "$HOME/.local/share/doc/C/glibc.html" ]] || (
        curl -L \
            https://sourceware.org/glibc/manual/latest/html_mono/libc.html \
            -o ~/.local/share/doc/C/glibc.html
    )
    [[ -f "$HOME/.local/share/doc/C/C-language.html" ]] || (
        curl -L \
            https://www.gnu.org/software/c-intro-and-ref/manual/c-intro-and-ref.html \
            -o ~/.local/share/doc/C/C-language.html
    )
    [[ -f "$HOME/.local/share/doc/C/c23.pdf" ]] || (
        curl -L \
            https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3220.pdf \
            -o ~/.local/share/doc/C/c23.pdf
    )
    [[ -f "$HOME/.local/share/doc/C++/cpp23.pdf" ]] || (
        curl -L \
            https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2023/n4950.pdf \
            -o ~/.local/share/doc/C++/cpp23.pdf
    )
    [[ -f "$HOME/.local/share/doc/C++/cppreference/reference/en/cpp/language.html" ]] || (
        mkdir -p "$HOME/.local/share/doc/C++/cppreference"
        set -o pipefail
        curl --fail --location \
            https://github.com/PeterFeicht/cppreference-doc/releases/download/v20250209/html-book-20250209.tar.xz \
            | tar -xJ -C "$HOME/.local/share/doc/C++/cppreference"
    )
    [[ -f "$HOME/.local/share/doc/C++/cplusplus/cplusplus.com/doc/tutorial/.complete" ]] || \
        mirror_cplusplus \
            https://cplusplus.com/doc/tutorial/ \
            "$HOME/.local/share/doc/C++/cplusplus/cplusplus.com/doc/tutorial/.complete"
    [[ -f "$HOME/.local/share/doc/C++/cplusplus/cplusplus.com/reference/.complete" ]] || \
        mirror_cplusplus \
            https://cplusplus.com/reference/ \
            "$HOME/.local/share/doc/C++/cplusplus/cplusplus.com/reference/.complete"
    [[ -d "$HOME/.local/share/doc/C++/libstdc++-manual-html" ]] || (
        curl -L https://gcc.gnu.org/onlinedocs/gcc-16.1.0/libstdc++-manual-html.tar.gz \
            | tar -xz -C ~/.local/share/doc/C++
    )
    [[ -d "$HOME/.local/share/doc/github-docs" ]] || (
        mkdir -p ~/.local/share/doc/github-docs
        git clone --depth 1 https://github.com/github/docs \
            ~/.local/share/doc/github-docs
        cd ~/.local/share/doc/github-docs
        npm ci
        npm run build
    )
    [[ -d "$HOME/.local/share/doc/docker" ]] || (
        mkdir -p ~/.local/share/doc/docker
        sudo --stdin systemctl start docker 2>/dev/null <<< "$PASSWORD"
        sudo --stdin docker buildx build \
        --target release \
          --build-arg BUILDKIT_CONTEXT_KEEP_GIT_DIR=1 \
          --build-arg DOCS_URL=http://localhost:8010 \
          --output type=local,dest="$HOME/.local/share/doc/docker" \
          https://github.com/docker/docs.git 2>/dev/null <<< "$PASSWORD"
    )
    [[ -d "$HOME/.local/share/doc/fastapi" ]] || (
        mkdir -p ~/.local/share/doc/fastapi
        git clone --depth 1 https://github.com/fastapi/fastapi \
            ~/.local/share/doc/fastapi
        cd ~/.local/share/doc/fastapi
        uv sync --group docs
        uv run python scripts/docs.py build-lang en
    )
    [[ -d "$HOME/.local/share/doc/make" ]] || (
        mkdir -p ~/.local/share/doc/make
        curl -L https://www.gnu.org/software/make/manual/make.html \
             -o ~/.local/share/doc/make/make.html
    )
    [[ -d "$HOME/.local/share/doc/gcc" ]] || (
        mkdir -p ~/.local/share/doc/gcc
        curl -L https://gcc.gnu.org/onlinedocs/gcc-16.1.0/gcc-html.tar.gz \
             | tar -xz -C ~/.local/share/doc/gcc
    )
    [[ -d "$HOME/.local/share/doc/nasm" ]] || (
        mkdir -p ~/.local/share/doc/nasm
        curl -L https://www.nasm.us/pub/nasm/releasebuilds/3.02/nasm-3.02-xdoc.tar.xz \
             | tar -xJ -C ~/.local/share/doc/nasm --strip-components=2
    )
}

main 
