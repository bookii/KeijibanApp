import SwiftData
import SwiftUI

public struct KAMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @Query private var boards: [KABoard]
    @State private var fetchedBoards: [KAFetchedBoard] = []
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
                KAKeijibanIndexView(fetchedBoards: fetchedBoards)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .errorAlert($error)
        .animation(.default, value: selectedTabIndex)
        .task {
            do {
                fetchedBoards = try await apiService.fetchBoards(withEntries: true)
                try syncService.syncBoards(fetchedBoards: fetchedBoards.map(\.board))
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
            .environment(\.syncService, KAMockSyncService())
    }
#endif
