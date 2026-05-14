#!/usr/bin/env bash

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ROOT_DIR/scripts/utils/make_sourced.sh"

export ROOT_DIR
export SCRIPTS_DIR="$ROOT_DIR/scripts"
