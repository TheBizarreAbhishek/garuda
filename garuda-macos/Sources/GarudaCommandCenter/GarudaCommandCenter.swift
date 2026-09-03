import SwiftUI

@main
public struct GarudaCommandCenterApp: App {
    public init() {
        if CommandLine.arguments.contains("--test") {
            let success = TestRunner.runAllTests()
            exit(success ? 0 : 1)
        }
    }
    
    public var body: some Scene {
        WindowGroup {
            MainAppView()
                .frame(minWidth: 1000, minHeight: 650)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
