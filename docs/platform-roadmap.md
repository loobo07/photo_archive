# Platform Roadmap

## v1: macOS CLI

- Export originals from Apple Photos using `osxphotos`.
- Target external drives mounted under `/Volumes`.
- Provide Homebrew-oriented setup docs.
- Run CI on `macos-latest`.

## Future: Cross-Platform Core

Future Windows and Linux support should start with a source abstraction:

- macOS backend: Apple Photos via `osxphotos`.
- Windows backend: a normal filesystem/photo-folder source.
- Linux backend: a normal filesystem/photo-folder source.

The portable core should own destination layouts, reports, dry-run behavior, and
resume/update semantics. Source backends should own how media and metadata are
read from each platform.

Do not claim Windows or Linux install support until a backend exists and is
covered by CI.
