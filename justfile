set shell := ["zsh", "-cu"]

default:
    @just --list

fmt-check:
    zsh -n scripts/export_photos_originals.zsh
    zsh -n tests/export_photos_originals_test.zsh

test:
    zsh tests/export_photos_originals_test.zsh

check: fmt-check test

print-command:
    scripts/export_photos_originals.zsh --print-command --target "/Volumes/My Photos" --limit 10

smoke target:
    scripts/export_photos_originals.zsh --target {{quote(target)}} --limit 10
