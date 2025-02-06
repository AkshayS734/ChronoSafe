import SwiftUI

@main
struct MyApp: App {
    @StateObject private var manager = TimeCapsuleManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
