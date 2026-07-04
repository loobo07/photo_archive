import PhotoArchiveCore
import SwiftUI

struct RunView: View {
  let store: ArchiveSessionStore

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Photo Archive")
            .font(.headline)
          Text(statusText)
            .foregroundStyle(statusColor)
        }

        Spacer()

        Button("Clear Logs") {
          store.clearLogs()
        }
        .disabled(store.phase.isRunning || store.logs.isEmpty)

        Button("Dry Run") {
          Task {
            await store.startDryRun()
          }
        }
        .keyboardShortcut("r", modifiers: [.command])
        .disabled(store.phase.isRunning)

        Button("Export") {
          Task {
            await store.startExport()
          }
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .disabled(!store.canExport || store.phase.isRunning)
      }

      if store.canExport {
        Text("Current options passed dry run. Export is enabled for this session.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }

  private var statusText: String {
    switch store.phase {
    case .editingOptions:
      return "Editing options"
    case .dryRunRunning:
      return "Dry run running"
    case .dryRunSucceeded:
      return "Dry run succeeded"
    case .exportRunning:
      return "Export running"
    case .exportSucceeded:
      return "Export succeeded"
    case .failed(let message):
      return message
    }
  }

  private var statusColor: Color {
    switch store.phase {
    case .dryRunSucceeded, .exportSucceeded:
      return .green
    case .failed:
      return .red
    case .dryRunRunning, .exportRunning:
      return .blue
    case .editingOptions:
      return .secondary
    }
  }
}
