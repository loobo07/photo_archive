import PhotoArchiveCore
import SwiftUI

struct LogView: View {
  let logs: [ProcessLogLine]

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(logs) { line in
            HStack(alignment: .top, spacing: 8) {
              Text(Self.timestampFormatter.string(from: line.timestamp))
                .foregroundStyle(.secondary)
                .frame(width: 76, alignment: .leading)
              Text(line.stream.rawValue)
                .foregroundStyle(line.stream == .stderr ? .red : .secondary)
                .frame(width: 48, alignment: .leading)
              Text(line.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(.caption, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .id(line.id)
          }
        }
        .padding(.vertical, 8)
      }
      .overlay {
        if logs.isEmpty {
          ContentUnavailableView("No Logs", systemImage: "text.alignleft")
        }
      }
      .onChange(of: logs.last?.id) { _, id in
        guard let id else {
          return
        }
        proxy.scrollTo(id, anchor: .bottom)
      }
    }
  }

  private static let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
