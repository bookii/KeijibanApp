import SwiftUI

public struct KAKeijibanView: View {
    private let fetchedBoard: KAFetchedBoard
    @State private var currentIndex: Int = 0

    public init(fetchedBoard: KAFetchedBoard) {
        self.fetchedBoard = fetchedBoard
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(fetchedBoard.board.name)
                .font(.title.bold())
            if !fetchedBoard.entries.isEmpty {
                VStack(spacing: 8) {
                    let entry = fetchedBoard.entries[currentIndex]
                    KAFlowLayout(alignment: .leading, spacing: 4) {
                        ForEach(entry.wordImages) { wordImage in
                            KALazyImageView(data: wordImage.imageData)
                                .frame(height: 48)
                                .frame(maxWidth: 72)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    Text(Date(timeIntervalSince1970: TimeInterval(entry.createdAt)).formatted(date: .long, time: .shortened))
                }
                .padding(16)
                .frame(maxHeight: .infinity)
                .background(Color(.tertiarySystemGroupedBackground))
                HStack(spacing: 16) {
                    Button {
                        currentIndex += 1
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowtriangle.backward.fill")
                            Text("過去へ")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .foregroundStyle(Color(.secondaryLabel))
                    .background(Color(.tertiarySystemGroupedBackground))
                    .opacity(currentIndex < fetchedBoard.entries.endIndex - 1 ? 1 : 0)
                    Button {
                        currentIndex -= 1
                    } label: {
                        HStack(spacing: 4) {
                            Text("未来へ")
                            Image(systemName: "arrowtriangle.forward.fill")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .foregroundStyle(Color(.secondaryLabel))
                    .background(Color(.tertiarySystemGroupedBackground))
                    .opacity(currentIndex > 0 ? 1 : 0)
                }
            } else {
                Text("掲示はありません")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockFetchedBoard: KAFetchedBoard?
        @Previewable @State var viewHeight: CGFloat?
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .overlay {
                if let mockFetchedBoard {
                    KAKeijibanView(fetchedBoard: mockFetchedBoard)
                        .frame(width: viewHeight.flatMap { $0 * 1.5 })
                }
            }
            .task {
                mockFetchedBoard = await .mockFetchedBoards().first
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                viewHeight = height
            }
    }
#endif
