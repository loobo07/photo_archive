# Release Guide

## First GitHub Publish

1. Confirm the default branch is `main`.
2. Confirm local checks pass:

   ```zsh
   just check
   ```

3. Create the GitHub repository:

   ```zsh
   gh repo create photo_archive --public --source=. --remote=origin --push
   ```

4. Confirm CI passes on GitHub.

## Versioned Release

1. Prepare the release notes text before creating the GitHub release.
2. Tag the release:

   ```zsh
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. Create the release:

   ```zsh
   gh release create v0.1.0 --title "v0.1.0" --notes "Initial macOS CLI release."
   ```

## Homebrew Follow-Up

The v1 install path documents Homebrew prerequisites, but does not ship a tap.
Add a Homebrew tap only after the CLI name, repo URL, and release artifact shape
stabilize.
