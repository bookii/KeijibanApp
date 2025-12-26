import SwiftUI

public struct KAKeijibanIndexView: View {
    @Environment(\.apiService) private var apiService
    @State private var boards = [KABoard]()
    @State private var viewHeight: CGFloat?

    public var body: some View {
        ScrollView {
            if boards.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: viewHeight)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(boards) { board in
                        Text(board.name)
                            .frame(maxWidth: .infinity)
                            .frame(height: viewHeight)
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            viewHeight = height
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .task {
            // TODO: エラー処理
            boards = await (try? apiService.fetchBoards()) ?? []
        }
    }
}

#if DEBUG
    #Preview {
        KAKeijibanIndexView()
            .environment(\.apiService, KAMockApiService())
    }
#endif
