#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "$TEST_DIR/.." && pwd -P)"

status=0
while IFS= read -r -d '' f; do
  echo "==> ${f#$TEST_DIR/}"
  if ! ROOT_DIR="$ROOT_DIR" bash "$f"; then
    status=1
  fi
  echo
done < <(find "$TEST_DIR" -type f -name '*_test.sh' -print0 | sort -z)

exit $status
