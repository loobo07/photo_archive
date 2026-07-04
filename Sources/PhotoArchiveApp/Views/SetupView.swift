import PhotoArchiveCore
import SwiftUI

struct SetupView: View {
  let store: ArchiveSessionStore

  var body: some View {
    Form {
      Section("Source") {
        TextField("Photos library", text: stringBinding(\.libraryPath))
      }

      Section("Destination") {
        TextField("Target volume", text: stringBinding(\.targetPath))
        TextField("Export folder", text: stringBinding(\.exportFolder))
        Picker("Layout", selection: layoutBinding) {
          ForEach(ExportLayout.allCases) { layout in
            Text(layout.rawValue).tag(layout)
          }
        }
      }

      Section("Date Scope") {
        Picker("Scope", selection: dateTargetKindBinding) {
          ForEach(DateTargetKind.allCases) { kind in
            Text(kind.title).tag(kind)
          }
        }

        switch dateTargetKind {
        case .fullArchive:
          EmptyView()
        case .hour:
          TextField("YYYY-MM-DDTHH", text: dateTargetValueBinding(defaultValue: "2024-07-19T14"))
        case .day:
          TextField("YYYY-MM-DD", text: dateTargetValueBinding(defaultValue: "2024-07-19"))
        case .month:
          TextField("YYYY-MM", text: dateTargetValueBinding(defaultValue: "2024-07"))
        case .range:
          TextField("From YYYY-MM-DD", text: rangeFromBinding)
          TextField("To YYYY-MM-DD", text: rangeToBinding)
        }
      }

      Section("Safety") {
        Stepper(value: intBinding(\.minimumFreeGB), in: 1...10_000, step: 25) {
          Text("Minimum free space: \(store.options.minimumFreeGB) GB")
        }

        Toggle("Limit test export", isOn: limitEnabledBinding)
        if store.options.limit != nil {
          Stepper(value: limitBinding, in: 1...1_000, step: 1) {
            Text("Limit: \(store.options.limit ?? 10)")
          }
        }
      }
    }
    .formStyle(.grouped)
    .padding()
    .disabled(store.phase.isRunning)
  }

  private func stringBinding(_ keyPath: WritableKeyPath<ExportOptions, String>) -> Binding<String> {
    Binding {
      store.options[keyPath: keyPath]
    } set: { value in
      var options = store.options
      options[keyPath: keyPath] = value
      store.updateOptions(options)
    }
  }

  private func intBinding(_ keyPath: WritableKeyPath<ExportOptions, Int>) -> Binding<Int> {
    Binding {
      store.options[keyPath: keyPath]
    } set: { value in
      var options = store.options
      options[keyPath: keyPath] = value
      store.updateOptions(options)
    }
  }

  private var layoutBinding: Binding<ExportLayout> {
    Binding {
      store.options.layout
    } set: { value in
      var options = store.options
      options.layout = value
      store.updateOptions(options)
    }
  }

  private var limitEnabledBinding: Binding<Bool> {
    Binding {
      store.options.limit != nil
    } set: { enabled in
      var options = store.options
      options.limit = enabled ? 10 : nil
      store.updateOptions(options)
    }
  }

  private var limitBinding: Binding<Int> {
    Binding {
      store.options.limit ?? 10
    } set: { value in
      var options = store.options
      options.limit = value
      store.updateOptions(options)
    }
  }

  private var dateTargetKind: DateTargetKind {
    DateTargetKind(target: store.options.dateTarget)
  }

  private var dateTargetKindBinding: Binding<DateTargetKind> {
    Binding {
      dateTargetKind
    } set: { kind in
      var options = store.options
      options.dateTarget = kind.defaultTarget
      store.updateOptions(options)
    }
  }

  private func dateTargetValueBinding(defaultValue: String) -> Binding<String> {
    Binding {
      switch store.options.dateTarget {
      case .hour(let value), .day(let value), .month(let value):
        return value
      case .fullArchive, .range:
        return defaultValue
      }
    } set: { value in
      var options = store.options
      switch dateTargetKind {
      case .hour:
        options.dateTarget = .hour(value)
      case .day:
        options.dateTarget = .day(value)
      case .month:
        options.dateTarget = .month(value)
      case .fullArchive:
        options.dateTarget = .fullArchive
      case .range:
        break
      }
      store.updateOptions(options)
    }
  }

  private var rangeFromBinding: Binding<String> {
    Binding {
      if case .range(let from, _) = store.options.dateTarget {
        return from
      }
      return "2024-07-01"
    } set: { value in
      var options = store.options
      let to: String
      if case .range(_, let existingTo) = store.options.dateTarget {
        to = existingTo
      } else {
        to = "2024-07-31"
      }
      options.dateTarget = .range(from: value, to: to)
      store.updateOptions(options)
    }
  }

  private var rangeToBinding: Binding<String> {
    Binding {
      if case .range(_, let to) = store.options.dateTarget {
        return to
      }
      return "2024-07-31"
    } set: { value in
      var options = store.options
      let from: String
      if case .range(let existingFrom, _) = store.options.dateTarget {
        from = existingFrom
      } else {
        from = "2024-07-01"
      }
      options.dateTarget = .range(from: from, to: value)
      store.updateOptions(options)
    }
  }
}

private enum DateTargetKind: String, CaseIterable, Identifiable {
  case fullArchive
  case hour
  case day
  case month
  case range

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .fullArchive:
      return "Full archive"
    case .hour:
      return "Hour"
    case .day:
      return "Day"
    case .month:
      return "Month"
    case .range:
      return "Date range"
    }
  }

  init(target: DateTarget) {
    switch target {
    case .fullArchive:
      self = .fullArchive
    case .hour:
      self = .hour
    case .day:
      self = .day
    case .month:
      self = .month
    case .range:
      self = .range
    }
  }

  var defaultTarget: DateTarget {
    switch self {
    case .fullArchive:
      return .fullArchive
    case .hour:
      return .hour("2024-07-19T14")
    case .day:
      return .day("2024-07-19")
    case .month:
      return .month("2024-07")
    case .range:
      return .range(from: "2024-07-01", to: "2024-07-31")
    }
  }
}
