import KeijibanCommonModule
import SwiftUI

public struct KAKeijibanIndexView: View {
    private let fetchedBoards: [KAFetchedBoard]
    @State private var selectedBoardId: UUID?
    @State private var viewHeight: CGFloat?
    @State private var isEditorSheetPresented: Bool = false
    @State private var error: Error?
    private var selectedBoard: KAFetchedBoard? {
        fetchedBoards.first(where: { $0.board.id == selectedBoardId })
    }

    public init(fetchedBoards: [KAFetchedBoard]) {
        self.fetchedBoards = fetchedBoards
    }

    public var body: some View {
        HStack(spacing: 0) {
            curtainView
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
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
        }
        .ignoresSafeArea()
        .scrollEdgeEffectHidden()
        .overlay(alignment: .topTrailing) {
            Button {
                isEditorSheetPresented = true
            } label: {
                Text("十")
                    .font(.stick(size: 20))
                    .frame(width: 20, height: 20)
                    .offset(y: -1)
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
    #Preview {
        @Previewable @State var mockFetchedBoards: [KAFetchedBoard] = []
        KAKeijibanIndexView(fetchedBoards: mockFetchedBoards)
            .task {
                mockFetchedBoards = await KAFetchedBoard.mockFetchedBoards()
            }
    }
#endif
