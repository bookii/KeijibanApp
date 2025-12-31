import SwiftData
import SwiftUI

public struct KAAnalyzerView: View {
    private let uiImage: UIImage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyzerService) private var analyzerService
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
        let originalImage = analyzeData.originalImage
        return VStack(spacing: 16) {
            Text("文字を見つけました！")
                .font(.title.bold())
            ZStack(alignment: .topLeading) {
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
            HStack(spacing: 8) {
                Text("カテゴリを選択")
                Picker("", selection: $selectedBoard) {
                    Text("未選択").tag(KABoard?(nil))
                    ForEach(boards) { board in
                        Text(board.name)
                            .tag(board)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(in: Capsule())
            .backgroundStyle(Color(.systemGray6))
            Button {
                do {
                    for wordImage in analyzeData.wordImages {
                        try modelContext.insert(KAStoredWordImage(from: wordImage))
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
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
            .disabled(selectedBoard == nil)
        }
        .padding(16)
    }
}

#if DEBUG
    private struct Preview: View {
        private let shouldFail: Bool
        @State var isSheetPresented = false
        @State private var uiImage: UIImage?

        fileprivate init(shouldFail: Bool = false) {
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
                .task {
                    isSheetPresented = true
                }
        }
    }

    #Preview("通常") {
        @Previewable @State var isSheetPresented = false
        let mockContainer = try! ModelContainer(for: KABoard.self, configurations: .init(isStoredInMemoryOnly: true))
        for mockBoard in KABoard.mockBoards {
            mockContainer.mainContext.insert(mockBoard)
        }
        return Preview().modelContainer(mockContainer)
    }

    #Preview("分析エラー") {
        Preview(shouldFail: true)
    }
#endif
