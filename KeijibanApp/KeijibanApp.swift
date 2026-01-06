import SwiftData
import SwiftUI

@main
public struct KeijibanApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            KAMainView()
                .preferredColorScheme(.light)
        }
        .environment(\.apiService, KAApiService.shared)
        .environment(\.syncService, KASyncService.shared)
        .environment(\.font, .kiyosuna(size: 16))
        .modelContainer(ModelContainer.shared)
    }
}
