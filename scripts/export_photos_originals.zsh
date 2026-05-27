#!/bin/zsh
set -euo pipefail

DEFAULT_LIBRARY="${HOME}/Pictures/Photos Library.photoslibrary"
DEFAULT_EXPORT_FOLDER="Photos Originals Export"
DEFAULT_LAYOUT="yyyy-mm-dd-type"
DEFAULT_MIN_FREE_GB=250

library="${DEFAULT_LIBRARY}"
target=""
export_folder="${DEFAULT_EXPORT_FOLDER}"
layout="${DEFAULT_LAYOUT}"
min_free_gb="${DEFAULT_MIN_FREE_GB}"
limit=""
print_template=0
print_command=0
dry_run_only=0
skip_dry_run=0

usage() {
  cat <<'USAGE'
Usage:
  scripts/export_photos_originals.zsh [options]

Options:
  --target PATH              Mounted external partition under /Volumes.
  --library PATH             Photos library path. Defaults to ~/Pictures/Photos Library.photoslibrary.
  --export-folder NAME       Folder created on target. Defaults to "Photos Originals Export".
  --layout NAME              yyyy-mm-dd-type or type-yy-mm-dd.
  --min-free-gb GB           Required target free space. Defaults to 250.
  --limit N                  Export at most N assets; useful for test runs.
  --dry-run-only             Run osxphotos dry-run and exit.
  --skip-dry-run             Skip the preflight dry-run before the real export.
  --print-template           Print the osxphotos directory template and exit.
  --print-command            Print the osxphotos export command and exit.
  -h, --help                 Show this help.

Examples:
  scripts/export_photos_originals.zsh
  scripts/export_photos_originals.zsh --target "/Volumes/My Photos" --limit 10
  scripts/export_photos_originals.zsh --layout type-yy-mm-dd
USAGE
}

die() {
  print -r -- "Error: $*" >&2
  exit 1
}

layout_template() {
  case "$1" in
    yyyy-mm-dd-type)
      print -r -- "{created.year}/{created.mm}/{created.dd}/{media_type}"
      ;;
    type-yy-mm-dd)
      print -r -- "{media_type}/{created.yy}/{created.mm}/{created.dd}"
      ;;
    *)
      die "unknown layout '${1}'. Use yyyy-mm-dd-type or type-yy-mm-dd."
      ;;
  esac
}

human_gb_to_kb() {
  local gb="$1"
  [[ "$gb" == <-> ]] || die "--min-free-gb must be a whole number"
  print -r -- "$((gb * 1024 * 1024))"
}

free_kb_for_path() {
  local target_path="$1"
  df -Pk "$target_path" | awk 'NR == 2 { print $4 }'
}

volume_filesystem() {
  local target_path="$1"
  diskutil info "$target_path" 2>/dev/null | awk -F: '
    /File System Personality/ { gsub(/^[ \t]+/, "", $2); print $2; exit }
    /Type \(Bundle\)/ { gsub(/^[ \t]+/, "", $2); print $2; exit }
  '
}

is_accepted_filesystem() {
  local fs="$1"
  [[ "$fs" == *APFS* || "$fs" == *"Mac OS Extended"* || "$fs" == *"Journaled HFS+"* ]]
}

is_rejected_volume_name() {
  local name="$1"
  [[ "$name" == "Macintosh HD" || "$name" == "com.apple.TimeMachine.localsnapshots" ]]
}

shell_quote_arg() {
  local arg="$1"
  case "$arg" in
    ""|*[!A-Za-z0-9_/:=.,+@%{}-]*)
      print -r -- "${(qq)arg}"
      ;;
    *)
      print -r -- "$arg"
      ;;
  esac
}

list_candidate_volumes() {
  local volume
  local required_kb
  local name
  local available_kb
  required_kb="$(human_gb_to_kb "$min_free_gb")"

  for volume in /Volumes/*(N/); do
    name="${volume:t}"
    is_rejected_volume_name "$name" && continue
    [[ -L "$volume" ]] && continue
    available_kb="$(free_kb_for_path "$volume")"
    (( available_kb >= required_kb )) || continue
    print -r -- "$volume"
  done
}

choose_target_volume() {
  local -a volumes
  local volume_lines
  volume_lines="$(list_candidate_volumes)"
  if [[ -z "$volume_lines" ]]; then
    volumes=()
  else
    volumes=("${(@f)volume_lines}")
  fi

  (( ${#volumes} > 0 )) || die "no external target volume found under /Volumes. Connect the drive, then run again."

  print -r -- "Mounted target candidates:"
  local i=1
  local volume
  local free_gb
  for volume in "${volumes[@]}"; do
    free_gb=$(( $(free_kb_for_path "$volume") / 1024 / 1024 ))
    print -r -- "  ${i}) ${volume} (${free_gb} GB free)"
    (( i++ ))
  done

  print -n -- "Choose target number: "
  local choice
  read -r choice
  [[ "$choice" == <-> ]] || die "choice must be a number"
  (( choice >= 1 && choice <= ${#volumes} )) || die "choice out of range"

  target="${volumes[$choice]}"
}

require_osxphotos() {
  command -v osxphotos >/dev/null 2>&1 && return

  print -r -- "osxphotos is not installed."
  print -r -- "Recommended install command: pipx install osxphotos"
  print -n -- "Install it now with pipx? [y/N] "
  local answer
  read -r answer
  if [[ "$answer" == [Yy]* ]]; then
    command -v pipx >/dev/null 2>&1 || die "pipx is not installed or not on PATH"
    pipx install osxphotos
  else
    die "install osxphotos, then run this script again"
  fi
}

validate_target() {
  [[ -n "$target" ]] || choose_target_volume
  [[ -d "$target" ]] || die "target does not exist or is not a directory: ${target}"
  [[ "$target" == /Volumes/* ]] || die "target must be a mounted volume under /Volumes"
  is_rejected_volume_name "${target:t}" && die "refusing to export to ${target}"

  local fs
  fs="$(volume_filesystem "$target")"
  [[ -n "$fs" ]] || die "could not determine filesystem for ${target}"
  is_accepted_filesystem "$fs" || die "target filesystem '${fs}' is not APFS or Mac OS Extended Journaled"

  local required_kb
  local available_kb
  required_kb="$(human_gb_to_kb "$min_free_gb")"
  available_kb="$(free_kb_for_path "$target")"
  (( available_kb >= required_kb )) || die "target has less than ${min_free_gb} GB free"
}

build_export_command() {
  local destination="$1"
  local template="$2"
  local dry_run="$3"
  local report_path="${destination}/export-report.csv"

  local -a cmd
  cmd=(
    osxphotos export "$destination"
    --library "$library"
    --directory "$template"
    --skip-edited
    --sidecar XMP
    --sidecar-drop-ext
    --download-missing
    --update
    --retry 3
    --report "$report_path"
    --touch-file
    --verbose
  )

  [[ -n "$limit" ]] && cmd+=(--limit "$limit")
  (( dry_run )) && cmd+=(--dry-run)

  local -a quoted_cmd
  local arg
  for arg in "${cmd[@]}"; do
    quoted_cmd+=("$(shell_quote_arg "$arg")")
  done

  print -r -- "${(j: :)quoted_cmd}"
}

run_export_command() {
  local destination="$1"
  local template="$2"
  local dry_run="$3"
  local -a cmd

  cmd=(
    osxphotos export "$destination"
    --library "$library"
    --directory "$template"
    --skip-edited
    --sidecar XMP
    --sidecar-drop-ext
    --download-missing
    --update
    --retry 3
    --report "${destination}/export-report.csv"
    --touch-file
    --verbose
  )

  [[ -n "$limit" ]] && cmd+=(--limit "$limit")
  (( dry_run )) && cmd+=(--dry-run)

  "${cmd[@]}"
}

while (( $# > 0 )); do
  case "$1" in
    --target)
      shift
      (( $# > 0 )) || die "--target requires a path"
      target="$1"
      ;;
    --library)
      shift
      (( $# > 0 )) || die "--library requires a path"
      library="$1"
      ;;
    --export-folder)
      shift
      (( $# > 0 )) || die "--export-folder requires a name"
      export_folder="$1"
      ;;
    --layout)
      shift
      (( $# > 0 )) || die "--layout requires a name"
      layout="$1"
      ;;
    --min-free-gb)
      shift
      (( $# > 0 )) || die "--min-free-gb requires a number"
      min_free_gb="$1"
      ;;
    --limit)
      shift
      (( $# > 0 )) || die "--limit requires a number"
      [[ "$1" == <-> ]] || die "--limit must be a whole number"
      limit="$1"
      ;;
    --dry-run-only)
      dry_run_only=1
      ;;
    --skip-dry-run)
      skip_dry_run=1
      ;;
    --print-template)
      print_template=1
      ;;
    --print-command)
      print_command=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

template="$(layout_template "$layout")"

if (( print_template )); then
  print -r -- "$template"
  exit 0
fi

if (( print_command )); then
  destination="${target:-/Volumes/ExternalDrive}/${export_folder}"
  build_export_command "$destination" "$template" 0
  exit 0
fi

[[ -d "$library" ]] || die "Photos library not found: ${library}"
validate_target
require_osxphotos

destination="${target}/${export_folder}"

print -r -- "Export destination: ${destination}"
print -r -- "Directory layout: ${template}"

if (( ! skip_dry_run )); then
  print -r -- "Running osxphotos dry-run first..."
  run_export_command "$destination" "$template" 1
fi

if (( dry_run_only )); then
  print -r -- "Dry run complete. No files were exported."
  exit 0
fi

print -n -- "Run the real export now? [y/N] "
read -r answer
[[ "$answer" == [Yy]* ]] || die "export cancelled"

mkdir -p "$destination"
run_export_command "$destination" "$template" 0
