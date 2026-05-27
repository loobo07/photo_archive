#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SCRIPT="${ROOT_DIR}/scripts/export_photos_originals.zsh"

fail() {
  print -r -- "FAIL: $*" >&2
  exit 1
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  [[ "$actual" == "$expected" ]] || fail "${message}: expected '${expected}', got '${actual}'"
}

template_default="$("${SCRIPT}" --print-template --layout yyyy-mm-dd-type)"
assert_equals "{created.year}/{created.mm}/{created.dd}/{media_type}" "${template_default}" "default layout template"

template_alt="$("${SCRIPT}" --print-template --layout type-yy-mm-dd)"
assert_equals "{media_type}/{created.yy}/{created.mm}/{created.dd}" "${template_alt}" "alternate layout template"

command_output="$("${SCRIPT}" --print-command --target /Volumes/PhotoDrive --layout yyyy-mm-dd-type --limit 10 --library "/Users/example/Pictures/Photos Library.photoslibrary")"

[[ "${command_output}" == *"osxphotos export"* ]] || fail "command output includes osxphotos export"
[[ "${command_output}" == *"--directory {created.year}/{created.mm}/{created.dd}/{media_type}"* ]] || fail "command output includes selected directory template"
[[ "${command_output}" == *"--skip-edited"* ]] || fail "command output exports originals only"
[[ "${command_output}" == *"--sidecar XMP"* ]] || fail "command output includes xmp sidecars"
[[ "${command_output}" == *"--download-missing"* ]] || fail "command output handles iCloud missing originals"
[[ "${command_output}" == *"--update"* ]] || fail "command output is resumable"
[[ "${command_output}" == *"--limit 10"* ]] || fail "command output supports limited test exports"

quoted_command_output="$("${SCRIPT}" --print-command --target "/Volumes/My Photos" --export-folder "Archive Export" --layout yyyy-mm-dd-type --limit 10 --library "/Users/example/Pictures/Photos Library.photoslibrary")"
[[ "${quoted_command_output}" == *"'/Volumes/My Photos/Archive Export'"* ]] || fail "print-command quotes destination paths with spaces"
[[ "${quoted_command_output}" == *"'/Users/example/Pictures/Photos Library.photoslibrary'"* ]] || fail "print-command quotes library paths with spaces"
[[ "${quoted_command_output}" == *"'Archive Export/export-report.csv'"* || "${quoted_command_output}" == *"'/Volumes/My Photos/Archive Export/export-report.csv'"* ]] || fail "print-command quotes report paths with spaces"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
fake_library="${tmp_dir}/Fake Photos Library.photoslibrary"
mkdir -p "${fake_library}"

no_target_output="$("${SCRIPT}" --dry-run-only --min-free-gb 999999 --library "${fake_library}" 2>&1 || true)"
[[ "${no_target_output}" == *"no external target volume found under /Volumes"* ]] || fail "no-target path exits before dependency installation"

fake_bin="${tmp_dir}/bin"
mkdir -p "${fake_bin}"

cat > "${fake_bin}/df" <<'EOF'
#!/bin/zsh
print -r -- "Filesystem 1024-blocks Used Available Capacity Mounted on"
print -r -- "/dev/test 999999999 1 999999998 1% /Volumes/SimpleX"
EOF

cat > "${fake_bin}/diskutil" <<'EOF'
#!/bin/zsh
print -r -- "   File System Personality: APFS"
EOF

cat > "${fake_bin}/osxphotos" <<'EOF'
#!/bin/zsh
[[ "$*" == *"--dry-run"* ]] || exit 44
exit 0
EOF

cat > "${fake_bin}/mkdir" <<'EOF'
#!/bin/zsh
if [[ "$*" == *"Dry Run Should Not Create"* ]]; then
  print -r -- "mkdir should not be called for dry-run-only" >&2
  exit 45
fi
command mkdir "$@"
EOF

chmod +x "${fake_bin}/df" "${fake_bin}/diskutil" "${fake_bin}/osxphotos" "${fake_bin}/mkdir"

dry_run_only_output="$(PATH="${fake_bin}:${PATH}" "${SCRIPT}" --dry-run-only --skip-dry-run --target "/Volumes/SimpleX" --export-folder "Dry Run Should Not Create" --min-free-gb 1 --library "${fake_library}" 2>&1)"
[[ "${dry_run_only_output}" == *"Dry run complete. No files were exported."* ]] || fail "dry-run-only exits without creating destination"

print -r -- "All export_photos_originals tests passed"
