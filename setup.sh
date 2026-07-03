#!/usr/bin/env bash

export ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

chmod +x "$ROOT_DIR"/scripts/install/*.sh
chmod +x "$ROOT_DIR"/scripts/system/*.sh
chmod +x "$ROOT_DIR"/scripts/utils/*.sh

source "$ROOT_DIR/scripts/utils/make_sourced.sh"

