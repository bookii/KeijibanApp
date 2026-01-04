import SwiftUI

public struct KAKeijibanIndexView: View {
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @State private var boards: [KABoard]?
    @State private var selectedBoardId: UUID?
    @State private var viewHeight: CGFloat?
    @State private var isEditorSheetPresented: Bool = false
    @State private var error: Error?
    private var selectedBoard: KABoard? {
        boards?.first(where: { $0.id == selectedBoardId })
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                if let boards {
                    LazyVStack(spacing: 0) {
                        ForEach(boards) { board in
                            Text(board.name)
                                .frame(maxWidth: .infinity)
                                .frame(height: viewHeight)
                                .id(board.id)
                        }
                    }
                    .scrollTargetLayout()
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
            .scrollPosition(id: $selectedBoardId)
            .scrollIndicators(.hidden)
            .errorAlert($error)
            .fullScreenCover(isPresented: $isEditorSheetPresented) {
                if let selectedBoard {
                    KAEditorView(board: selectedBoard, isPresented: $isEditorSheetPresented)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "square.and.pencil") {
                        isEditorSheetPresented = true
                    }
                    .disabled(selectedBoardId == nil)
                }
            }
            .task {
                do {
                    let fetchedBoards = try await apiService.fetchBoards(withEntries: true)
                    boards = fetchedBoards
                    selectedBoardId = fetchedBoards.first?.id
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
}

#if DEBUG
    #Preview("通常") {
        KAKeijibanIndexView()
            .environment(\.apiService, KAMockApiService())
            .environment(\.syncService, KAMockSyncService())
    }

    #Preview("取得エラー") {
        KAKeijibanIndexView()
            .environment(\.apiService, KAMockApiService(shouldFail: true))
            .environment(\.syncService, KAMockSyncService())
    }
#endif
