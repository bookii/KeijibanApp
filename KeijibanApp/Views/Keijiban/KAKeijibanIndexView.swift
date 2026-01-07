import KeijibanCommonModule
import SwiftUI

public struct KAKeijibanIndexView: View {
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @State private var fetchedBoards: [KAFetchedBoard]?
    @State private var selectedBoardId: UUID?
    @State private var viewHeight: CGFloat?
    @State private var isEditorSheetPresented: Bool = false
    @State private var error: Error?
    private var selectedBoard: KAFetchedBoard? {
        fetchedBoards?.first(where: { $0.board.id == selectedBoardId })
    }

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            if let fetchedBoards {
                curtainView
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(fetchedBoards) { fetchedBoard in
                            KAKeijibanView(fetchedBoard: fetchedBoard)
                                .frame(width: viewHeight.flatMap { $0 * 1.5 })
                                .frame(maxHeight: .infinity)
                                .id(fetchedBoard.board.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $selectedBoardId)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .frame(width: viewHeight.flatMap { $0 * 1.5 })
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    viewHeight = height
                }
                curtainView
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .scrollEdgeEffectHidden()
        .overlay(alignment: .topTrailing) {
            Button {
                isEditorSheetPresented = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .offset(x: 1, y: -1)
                    .padding(1)
            }
            .buttonStyle(.glass)
            .clipShape(.circle)
            .offset(x: -24, y: 24)
            .ignoresSafeArea(edges: [.top, .trailing])
        }
        .errorAlert($error)
        .fullScreenCover(isPresented: $isEditorSheetPresented) {
            if let selectedBoard {
                KAEditorView(board: selectedBoard.board, isPresented: $isEditorSheetPresented)
            } else {
                Color.clear
                    .onAppear {
                        isEditorSheetPresented = false
                    }
            }
        }
        .task {
            do {
                let fetchedBoards = try await apiService.fetchBoards(withEntries: true)
                self.fetchedBoards = fetchedBoards
                selectedBoardId = fetchedBoards.first?.board.id
                try? syncService.syncBoards(fetchedBoards: fetchedBoards.map(\.board))
            } catch let error as KALocalizedError {
                self.error = error
                fetchedBoards = []
            } catch {
                self.error = KALocalizedError.wrapping(error)
                fetchedBoards = []
            }
        }
        .background(Color.kaKeijibanBackground)
    }

    private var curtainView: some View {
        Rectangle()
            .fill(Color.white.opacity(0.4))
            .frame(maxHeight: .infinity)
            .ignoresSafeArea()
            .zIndex(1)
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
