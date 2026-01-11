import KeijibanCommonModule
import SwiftUI

public struct KAKeijibanIndexView: View {
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @Binding private var boards: [KABoard]
    @State private var selectedBoardId: UUID?
    @State private var viewHeight: CGFloat?
    @State private var isEditorSheetPresented: Bool = false
    @State private var error: Error?
    private var selectedBoard: KABoard? {
        boards.first(where: { $0.id == selectedBoardId })
    }

    public init(boards: Binding<[KABoard]>) {
        _boards = boards
    }

    public var body: some View {
        HStack(spacing: 0) {
            curtainView
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(boards) { board in
                        KAKeijibanView(board: board)
                            .frame(width: viewHeight.flatMap { $0 * 1.5 })
                            .frame(maxHeight: .infinity)
                            .id(board.id)
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
                KAEditorView(board: selectedBoard, isPresented: $isEditorSheetPresented)
            } else {
                Color.clear
                    .onAppear {
                        isEditorSheetPresented = false
                    }
            }
        }
        .onAppear {
            selectedBoardId = boards.first?.id
        }
        .onChange(of: isEditorSheetPresented) { oldValue, newValue in
            if oldValue, !newValue {
                Task {
                    do {
                        boards = try await apiService.fetchBoards()
                        try syncService.syncBoards(boards)
                    } catch {
                        self.error = KALocalizedError.wrapping(error)
                    }
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
        @Previewable @State var mockBoards: [KABoard] = []
        KAKeijibanIndexView(boards: $mockBoards)
            .task {
                mockBoards = await KABoard.mockBoards()
            }
    }
#endif
