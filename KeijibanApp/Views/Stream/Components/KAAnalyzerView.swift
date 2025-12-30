import SwiftUI

public struct KAAnalyzerView: View {
    private let uiImage: UIImage
    @Environment(\.analyzerService) private var analyzerService
    @Environment(\.dismiss) private var dismiss
    @State private var analyzeData: KAAnalyzeData?
    @State private var zoomRatio: CGFloat = 1
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
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        Color.white.opacity(0.8)
                    }
                    .onGeometryChange(for: CGSize.self, of: \.size) { containerSize in
                        let imageSize = analyzeData.originalImage.size
                        guard imageSize != .zero else {
                            return
                        }
                        zoomRatio = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
                    }
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
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

#if DEBUG
    private struct Preview: View {
        private let shouldFail: Bool
        @State private var uiImage: UIImage?

        fileprivate init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        fileprivate var body: some View {
            Group {
                if let uiImage {
                    KAAnalyzerView(uiImage: uiImage)
                } else {
                    Color.clear
                }
            }
            .environment(\.analyzerService, KAMockAnalyzerService(shouldFail: shouldFail))
            .task {
                uiImage = await UIImage.mockImage()
            }
        }
    }

    #Preview("通常") {
        Preview()
    }

    #Preview("分析エラー") {
        @Previewable @State var isSheetPresented = false
        Color.clear
            .sheet(isPresented: $isSheetPresented) {
                Preview(shouldFail: true)
            }
            .task {
                isSheetPresented = true
            }
    }
#endif
