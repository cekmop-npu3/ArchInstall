#!/usr/bin/bash

function main () {
    [[ -d "~/.local/share/doc/C" ]] || (
        mkdir -p ~/.local/share/doc/C
        curl -L \
            https://sourceware.org/glibc/manual/latest/html_mono/libc.html \
            -o ~/.local/share/doc/C/glibc.html
        curl -L \
            https://www.gnu.org/software/c-intro-and-ref/manual/c-intro-and-ref.html \
            -o ~/.local/share/doc/C/C-language.html
    )
    [[ -d "~/.local/share/doc/github-docs" ]] || (
        mkdir -p ~/.local/share/doc/github-docs
        git clone --depth 1 https://github.com/github/docs \
            ~/.local/share/docs/github-docs
        cd ~/.local/share/docs/github-docs
        npm ci
        npm run build
    )
    [[ -d "~/.local/share/doc/docker" ]] || (
        mkdir -p ~/.local/share/doc/docker
        docker buildx build \
            --target release \
            --build-arg DOCS_URL=http://localhost:8010 \
            --output type=local,dest="$HOME/.local/share/doc/docker" \
            https://github.com/docker/docs.git
    )
    [[ -d "~/.local/share/doc/fastapi" ]] || (
        mkdir -p ~/.local/share/doc/fastapi
        git clone --depth 1 https://github.com/fastapi/fastapi \
            ~/.local/share/doc/fastapi
        cd ~/.local/share/doc/fastapi
        uv sync --group docs
        uv run python scripts/docs.py build-lang en
    )
}

main 

