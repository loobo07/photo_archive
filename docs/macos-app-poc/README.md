# macOS App POC Docs

This folder captures the simple architecture for a native macOS POC around the
existing Photo Archive CLI.

Read order for humans and controller agents:

1. [Scope](scope.md)
2. [Technical Architecture](technical-architecture.md)
3. [Design](design.md)
4. [Diagrams](diagrams.md)
5. [UML](uml.md)
6. [Agent Context Packet](agent-context-packet.md)

The POC goal is to prove that a SwiftUI app can safely orchestrate
`scripts/export_photos_originals.zsh` while preserving the current CLI safety
contract.

## Current Implementation

The POC is implemented as a SwiftPM package:

- `PhotoArchiveCore`: models, process runner, and session store.
- `PhotoArchiveApp`: SwiftUI wrapper app.
- `PhotoArchiveCoreTestRunner`: package-local verification runner.

Run the automated checks:

```zsh
swift run PhotoArchiveCoreTestRunner
swift build --product PhotoArchiveApp
just check
```

Run the app:

```zsh
./script/build_and_run.sh
```

Verify that the generated `.app` launches:

```zsh
./script/build_and_run.sh --verify
```

The app remains a control plane over the CLI. It does not parse Photos directly,
rewrite export behavior, or bypass the existing zsh safety checks.
