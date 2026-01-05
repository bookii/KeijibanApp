import SwiftData
import SwiftUI

public struct KAMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @Query private var boards: [KABoard]
    @State private var selectedTabIndex: Int = 1
    @State private var error: Error?

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab(value: 0) {
                KAGalleryView()
            }
            Tab(value: 1) {
                KAIndexView()
            }
            Tab(value: 2) {
                KAKeijibanIndexView()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .errorAlert($error)
        .task {
            if boards.isEmpty {
                do {
                    let fetchedBoards = try await apiService.fetchBoards(withEntries: false)
                    try syncService.syncBoards(fetchedBoards: fetchedBoards.map(\.board))
                    for board in boards {
                        modelContext.insert(board)
                    }
                    if modelContext.hasChanges {
                        try modelContext.save()
                    }
                } catch {
                    self.error = KALocalizedError.wrapping(error)
                }
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
