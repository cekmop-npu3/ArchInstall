#!/usr/bin/bash

declare PASSWORD=""
read -t 0 && read -r PASSWORD

function main () {
    [[ -d "$HOME/.local/share/doc/C" ]] || (
        mkdir -p ~/.local/share/doc/C
        curl -L \
            https://sourceware.org/glibc/manual/latest/html_mono/libc.html \
            -o ~/.local/share/doc/C/glibc.html
        curl -L \
            https://www.gnu.org/software/c-intro-and-ref/manual/c-intro-and-ref.html \
            -o ~/.local/share/doc/C/C-language.html
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
}

main 

