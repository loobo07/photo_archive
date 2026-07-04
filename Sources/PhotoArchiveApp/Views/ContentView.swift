import PhotoArchiveCore
import SwiftUI

struct ContentView: View {
  let store: ArchiveSessionStore

  var body: some View {
    VStack(spacing: 0) {
      HSplitView {
        SetupView(store: store)
          .frame(minWidth: 340, idealWidth: 380, maxWidth: 440)

        VStack(spacing: 0) {
          RunView(store: store)
          Divider()
          LogView(logs: store.logs)
        }
        .frame(minWidth: 480)
      }
    }
  }
}
