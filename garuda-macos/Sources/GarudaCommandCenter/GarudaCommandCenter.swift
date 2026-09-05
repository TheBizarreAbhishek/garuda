import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.collectionBehavior.insert([.fullScreenPrimary, .fullScreenAllowsTiling])
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

@main
public struct GarudaCommandCenterApp: App {
    public init() {
        if CommandLine.arguments.contains("--test") {
            let success = TestRunner.runAllTests()
            exit(success ? 0 : 1)
        }
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    public var body: some Scene {
        WindowGroup {
            MainAppView()
                .frame(minWidth: 1000, idealWidth: 1400, maxWidth: .infinity, minHeight: 650, idealHeight: 900, maxHeight: .infinity)
                .background(WindowAccessor())
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .windowSize) {
                Button("Toggle Full Screen") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
            }
        }
    }
}

