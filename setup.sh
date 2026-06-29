#!/usr/bin/env bash

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

export $ROOT_DIR
source "$ROOT_DIR/scripts/utils/make_sourced.sh"

