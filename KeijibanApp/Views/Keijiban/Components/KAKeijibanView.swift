import SwiftUI

public struct KAKeijibanView: View {
    private let board: KABoard
    private let fetchCount: Int = 1
    @Environment(\.apiService) private var apiService
    @State private var entries: [KAEntry]?
    @State private var currentIndex: Int?
    @State private var hasNoMoreEntries: Bool = false
    @State private var error: Error?

    public init(board: KABoard) {
        self.board = board
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(board.name)
                .font(.kuramubon(size: 24))
            Group {
                if let entries, let currentIndex {
                    if entries.indices.contains(currentIndex) {
                        entryView(entries[currentIndex])
                    } else {
                        Text("掲示はありません")
                    }
                } else {
                    ProgressView()
                        .tint(Color.white)
                        .onAppear {
                            loadMoreEntries()
                        }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.kaKeijibanSecondaryBackground)
            .border(Color.kaBorder, width: 4)
            controlView
        }
        .padding(16)
        .foregroundStyle(Color.white)
        .background(Color.kaKeijibanBackground)
        .errorAlert($error)
        .onChange(of: currentIndex) { _, newIndex in
            if let entries, let newIndex, newIndex == entries.endIndex - 1 {
                loadMoreEntries()
            }
        }
    }

    private func entryView(_ entry: KAEntry) -> some View {
        VStack(spacing: 8) {
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
                .foregroundStyle(Color.white)
        }
    }

    private var controlView: some View {
        HStack(spacing: 16) {
            Button {
                guard currentIndex != nil else {
                    fatalError("Button must not be visible")
                }
                currentIndex! += 1
            } label: {
                HStack(spacing: 4) {
                    Text("く")
                        .font(.stick(size: 16))
                        .frame(width: 16, height: 16)
                        .offset(y: -1)
                    Text("過去へ")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .foregroundStyle(Color.kaGray)
            .background(Color.kaLightGray)
            .clipShape(.capsule)
            .opacity({
                if let entries, let currentIndex {
                    currentIndex < entries.endIndex - 1 ? 1 : 0
                } else {
                    0
                }
            }())
            Button {
                guard currentIndex != nil else {
                    fatalError("Button must not be visible")
                }
                currentIndex! -= 1
            } label: {
                HStack(spacing: 4) {
                    Text("未来へ")
                    Text("く")
                        .font(.stick(size: 16))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(180))
                        .offset(y: 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .foregroundStyle(Color.kaGray)
            .background(Color.kaLightGray)
            .clipShape(.capsule)
            .opacity({
                if let currentIndex {
                    currentIndex > 0 ? 1 : 0
                } else {
                    0
                }
            }())
        }
    }

    private func loadMoreEntries() {
        if hasNoMoreEntries {
            return
        }
        Task {
            do {
                let oldestCreatedAt = entries?.last?.createdAt
                let fetchedEntries = try await apiService.fetchEntries(boardId: board.id, previousOldestCreatedAt: oldestCreatedAt, count: fetchCount).sorted { $0.createdAt > $1.createdAt }
                await MainActor.run {
                    entries = (entries ?? []) + fetchedEntries
                    if currentIndex == nil {
                        currentIndex = 0
                    }
                    if fetchedEntries.isEmpty {
                        hasNoMoreEntries = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    entries = []
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockBoard: KABoard?
        @Previewable @State var viewHeight: CGFloat?
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .overlay {
                if let mockBoard {
                    KAKeijibanView(board: mockBoard)
                        .frame(width: viewHeight.flatMap { $0 * 1.5 })
                }
            }
            .task {
                mockBoard = await .mockBoards().first
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                viewHeight = height
            }
            .environment(\.apiService, KAMockApiService())
    }
#endif
