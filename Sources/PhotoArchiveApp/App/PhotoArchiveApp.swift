import AppKit
import PhotoArchiveCore
import SwiftUI

@main
struct PhotoArchiveApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @State private var store = ArchiveSessionStore()

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
        .frame(minWidth: 920, minHeight: 620)
    }
    .commands {
      CommandGroup(replacing: .newItem) {}
    }
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
  }
}
