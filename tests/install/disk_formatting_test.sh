#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/install/disk_formatting_test.sh" "$@"

out="$(run_script scripts/install/disk_formatting.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "disk_formatting help is reachable"

if [[ "${ALLOW_DISK_INTEGRATION_TEST:-0}" != "1" ]]; then
  pass "disk_formatting integration skipped (set ALLOW_DISK_INTEGRATION_TEST=1)"
  finish
  exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
  pass "disk_formatting integration skipped (requires root)"
  finish
  exit 0
fi

if ! [[ -d /run/archiso ]] || ! command -v arch-chroot >/dev/null 2>&1; then
  pass "disk_formatting integration skipped (requires Arch ISO/live environment)"
  finish
  exit 0
fi

if ! command -v losetup >/dev/null 2>&1 || ! command -v sfdisk >/dev/null 2>&1 || ! command -v partprobe >/dev/null 2>&1; then
  pass "disk_formatting integration skipped (missing losetup/sfdisk/partprobe)"
  finish
  exit 0
fi

supports_gpt=1
if ! [[ -d /sys/firmware/efi ]]; then
  supports_gpt=0
fi

run_case() {
  local partition="$1"
  local mode="$2"
  local swap="$3"
  local case_name="$partition+$mode+swap=$swap"
  local img="/tmp/archinstall-test-${partition}-${mode}-${swap}.img"
  local loopdev=

  truncate -s 24G "$img"
  loopdev="$(losetup --show -f "$img")" || {
    rm -f "$img"
    fail "disk_formatting $case_name (failed to attach loop device)"
    return
  }

  umount -R /mnt >/dev/null 2>&1 || true
  swapoff -a >/dev/null 2>&1 || true

  local -a args=("-d" "$loopdev" "-p" "$partition" "-r" "8")
  if [[ "$swap" == "1" ]]; then
    args+=("-s" "1")
  fi
  case "$mode" in
    lvm) args+=("-l") ;;
    luks) PASSWORD="test-pass" args+=("-L" "-") ;;
    lvm_luks) PASSWORD="test-pass" args+=("-l" "-L" "-") ;;
  esac

  if run_script scripts/install/disk_formatting.sh "${args[@]}" >/tmp/diskfmt-test.log 2>&1; then
    if lsblk -ln "$loopdev" | grep -Eq "$(basename "$loopdev")p?1"; then
      pass "disk_formatting $case_name"
    else
      fail "disk_formatting $case_name (no boot partition, see /tmp/diskfmt-test.log)"
    fi
  else
    fail "disk_formatting $case_name failed (see /tmp/diskfmt-test.log)"
  fi

  umount -R /mnt >/dev/null 2>&1 || true
  swapoff -a >/dev/null 2>&1 || true
  losetup -d "$loopdev" >/dev/null 2>&1 || true
  rm -f "$img"
}

for partition in MBR GPT; do
  if [[ "$partition" == "GPT" && "$supports_gpt" -eq 0 ]]; then
    pass "disk_formatting GPT matrix skipped (UEFI not detected)"
    continue
  fi
  for mode in none lvm luks lvm_luks; do
    run_case "$partition" "$mode" "0"
    run_case "$partition" "$mode" "1"
  done
done

unset PASSWORD || true

finish
