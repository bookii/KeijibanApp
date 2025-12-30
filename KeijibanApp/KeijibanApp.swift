import SwiftData
import SwiftUI

@main
public struct KeijibanApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            KAMainView()
        }
        .environment(\.apiService, KAApiService.shared)
        .environment(\.syncService, KASyncService.shared)
        .modelContainer(ModelContainer.shared)
    }
}
