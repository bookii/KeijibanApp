import SwiftData
import SwiftUI

public struct KAMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @State private var boards: [KABoard] = []
    @State private var selectedTabIndex: Int = 1
    @State private var error: Error?

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab(value: 0) {
                KAGalleryView()
            }
            Tab(value: 1) {
                KAIndexView(selectedTabIndex: $selectedTabIndex)
            }
            Tab(value: 2) {
                KAKeijibanIndexView(boards: $boards)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .errorAlert($error)
        .animation(.default, value: selectedTabIndex)
        .task {
            do {
                boards = try await apiService.fetchBoards()
                try syncService.syncBoards(boards)
            } catch {
                self.error = KALocalizedError.wrapping(error)
            }
        }
    }
}

#if DEBUG
    #Preview {
        KAMainView()
            .environment(\.apiService, KAMockApiService())
            .environment(\.syncService, KAMockSyncService.shared)
    }
#endif
