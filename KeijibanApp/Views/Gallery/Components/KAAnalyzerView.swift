import SwiftData
import SwiftUI

public struct KAAnalyzerView: View {
    private let uiImage: UIImage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyzerService) private var analyzerService
    @Environment(\.apiService) private var apiService
    @Environment(\.syncService) private var syncService
    @Environment(\.dismiss) private var dismiss
    @Query private var boards: [KABoard]
    @State private var analyzeData: KAAnalyzeData?
    @State private var zoomRatio: CGFloat?
    @State private var selectedBoard: KABoard?
    @State private var isDataSaved: Bool = false
    @State private var error: KALocalizedError?

    public init(uiImage: UIImage) {
        self.uiImage = uiImage
    }

    public var body: some View {
        Group {
            if let analyzeData {
                resultView(analyzeData: analyzeData)
            } else {
                ProgressView()
            }
        }
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
            Button("OK") {
                dismiss()
            }
        }
        .alert("見つけた文字を保存しました！", isPresented: $isDataSaved) {
            Button("OK") {
                dismiss()
            }
        }
        .task {
            do {
                analyzeData = try await analyzerService.analyzeImage(uiImage)
            } catch let error as KALocalizedError {
                self.error = error
            } catch {
                self.error = KALocalizedError.wrapping(error)
            }
        }
    }

    private func resultView(analyzeData: KAAnalyzeData) -> some View {
        VStack(spacing: 12) {
            Text("文字を見つけました！")
                .font(.title.bold())
            imagesView(analyzeData: analyzeData)
            pickerView
            saveButton(analyzeData: analyzeData)
                .buttonStyle(.glassProminent)
                .disabled(selectedBoard == nil)
        }
        .padding(16)
        .task {
            if boards.isEmpty {
                do {
                    let fetchedBoards = try await apiService.fetchBoards()
                    try syncService.syncBoards(fetchedBoards: fetchedBoards)
                    for board in boards {
                        modelContext.insert(board)
                    }
                    if modelContext.hasChanges {
                        try modelContext.save()
                    }
                } catch let error as KALocalizedError {
                    self.error = error
                } catch {
                    self.error = KALocalizedError.wrapping(error)
                }
            }
        }
    }

    private func imagesView(analyzeData: KAAnalyzeData) -> some View {
        let originalImage = analyzeData.originalImage
        return ZStack(alignment: .topLeading) {
            Image(uiImage: originalImage)
                .resizable()
                .scaledToFit()
                .overlay {
                    Color.white.opacity(0.8)
                }
            if let zoomRatio {
                ForEach(analyzeData.wordImages, id: \.self) { wordImage in
                    let previewImage = wordImage.previewImage
                    let originInOriginalImage = wordImage.originInOriginalImage
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: previewImage.size.width * zoomRatio, height: previewImage.size.height * zoomRatio)
                        .border(Color(.systemGray2), width: 2)
                        .offset(x: originInOriginalImage.x * zoomRatio, y: originInOriginalImage.y * zoomRatio)
                }
            }
        }
        .clipped()
        .frame(maxHeight: .infinity, alignment: .top)
        .onGeometryChange(for: CGSize.self, of: \.size) { containerSize in
            let imageSize = analyzeData.originalImage.size
            guard imageSize != .zero else {
                return
            }
            zoomRatio = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        }
    }

    private var pickerView: some View {
        HStack(spacing: 8) {
            Text("カテゴリを選択")
            Group {
                if boards.isEmpty {
                    ProgressView()
                } else {
                    Picker("", selection: $selectedBoard) {
                        Text("未選択").tag(KABoard?(nil))
                        ForEach(boards) { board in
                            Text(board.name)
                                .tag(Optional(board))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(in: Capsule())
        .backgroundStyle(Color(.systemGray6))
    }

    private func saveButton(analyzeData: KAAnalyzeData) -> some View {
        Button {
            guard let selectedBoard else {
                fatalError("selectedBoard must not be nil")
            }
            do {
                for wordImage in analyzeData.wordImages {
                    try modelContext.insert(KAStoredWordImage(analyzedWordImage: wordImage, board: selectedBoard))
                }
                if modelContext.hasChanges {
                    try modelContext.save()
                }
                isDataSaved = true
            } catch let error as KALocalizedError {
                self.error = error
            } catch {
                self.error = KALocalizedError.wrapping(error)
            }
        } label: {
            Text("見つけた文字を保存する")
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
        .background(in: Capsule())
        .backgroundStyle(Color.blue)
        .glassEffect()
    }
}

#if DEBUG
    private struct Preview: View {
        private let shouldFail: Bool
        private let modelContainer: ModelContainer
        @State var isSheetPresented = false
        @State private var uiImage: UIImage?

        fileprivate init(shouldFail: Bool = false) {
            do {
                modelContainer = try .init(for: KABoard.self, configurations: .init(isStoredInMemoryOnly: true))
            } catch {
                fatalError("Failed to init modelContainer: \(error.localizedDescription)")
            }
            self.shouldFail = shouldFail
        }

        fileprivate var body: some View {
            Color.clear
                .sheet(isPresented: $isSheetPresented) {
                    Group {
                        if let uiImage {
                            KAAnalyzerView(uiImage: uiImage)
                        } else {
                            Color.clear
                        }
                    }
                    .task {
                        uiImage = await UIImage.mockImage()
                    }
                }
                .environment(\.analyzerService, KAMockAnalyzerService(shouldFail: shouldFail))
                .environment(\.apiService, KAMockApiService())
                .environment(\.syncService, KAMockSyncService(modelContainer: modelContainer))
                .modelContainer(modelContainer)
                .task {
                    isSheetPresented = true
                }
        }
    }

    #Preview("通常") {
        Preview()
    }

    #Preview("分析エラー") {
        Preview(shouldFail: true)
    }
#endif
