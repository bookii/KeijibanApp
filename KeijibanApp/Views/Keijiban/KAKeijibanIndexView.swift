import SwiftUI

public struct KAKeijibanIndexView: View {
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @State private var boards: [KABoard]?
    @State private var viewHeight: CGFloat?
    @State private var error: KALocalizedError?

    public init() {}

    public var body: some View {
        ScrollView {
            if let boards {
                LazyVStack(spacing: 0) {
                    ForEach(boards) { board in
                        Text(board.name)
                            .frame(maxWidth: .infinity)
                            .frame(height: viewHeight)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: viewHeight)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            viewHeight = height
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .alert(
            isPresented: Binding(
                get: { error != nil },
                set: { isPresented in
                    if !isPresented {
                        error = nil
                    }
                },
            ),
            error: error,
        ) {
            Button("OK") {}
        }
        .task {
            do {
                let fetchedBoards = try await apiService.fetchBoards()
                boards = fetchedBoards
                try? syncService.syncBoards(fetchedBoards: fetchedBoards)
            } catch let error as KALocalizedError {
                self.error = error
                boards = []
            } catch {
                self.error = KALocalizedError.wrapping(error)
                boards = []
            }
        }
    }
}

#if DEBUG
    #Preview("通常") {
        KAKeijibanIndexView()
            .environment(\.apiService, KAMockApiService())
            .environment(\.syncService, KAMockSyncService.shared)
    }

    #Preview("取得エラー") {
        KAKeijibanIndexView()
            .environment(\.apiService, KAMockApiService(shouldFail: true))
            .environment(\.syncService, KAMockSyncService.shared)
    }
#endif
