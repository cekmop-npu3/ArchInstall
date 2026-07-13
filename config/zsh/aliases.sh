#!/usr/bin/bash

source "$ROOT_DIR/scripts/utils/make_sourced.sh"

alias python-docs='xdg-open /usr/share/doc/python/html/index.html'
alias pydoc='python -m pydoc -b'
alias fastapi-docs='xdg-open ~/.local/share/doc/fastapi/site/index.html'
alias bash-docs='xdg-open /usr/share/doc/bash/bash.html'
alias cmake-docs='xdg-open /usr/share/doc/cmake/html/index.html'
alias postgresql-docs='xdg-open /usr/share/doc/postgresql/html/index.html'
alias c-docs='xdg-open ~/.local/share/doc/C/C-language.html'
alias glibc-docs='xdg-open ~/.local/share/doc/C/glibc.html'
alias make-docs='xdg-open ~/.local/share/doc/make/make.html'
alias gcc-docs='xdg-open ~/.local/share/doc/gcc/gcc/index.html'
alias clang-docs='xdg-open /usr/share/doc/clang/html/UsersManual.html'
alias clangd-docs='xdg-open /usr/share/doc/clang-tools/html/clangd/index.html'
alias lua-docs='xdg-open /usr/share/doc/lua/manual.html'

function clear-history () {
    : > "$HISTFILE"
    fc -p "$HISTFILE"
}

# Parameters:
#  $1 -> documentation directory
#  $2 -> URL to open
#  $3 -> server command and arguments
function _open_docs() {
    (
        local docs_path="$1"
        local docs_url="$2"
        shift 2
        cd "$docs_path" || return 1

        {
            for _ in {1..120}; do
                if curl --silent --fail "$docs_url" >/dev/null; then
                    xdg-open "$docs_url" >/dev/null 2>&1
                    return 0
                fi
                sleep 0.25
            done
        } & "$@"
    )
}

function github-docs () {
    _open_docs \
          "$HOME/.local/share/doc/github-docs" \
          "http://localhost:4000/en/actions" \
          npm run start-for-ci
}

function docker-docs () {
    _open_docs \
        "$HOME/.local/share/doc/docker" \
        "http://localhost:8010" \
        python -m http.server 8010
}

