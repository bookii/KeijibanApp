import SwiftUI

public struct KAAnalyzerView: View {
    private let uiImage: UIImage
    @Environment(\.analyzerService) private var analyzerService
    @Environment(\.dismiss) private var dismiss
    @State private var wordImages: [KAWordImage]?
    @State private var error: KALocalizedError?

    public init(uiImage: UIImage) {
        self.uiImage = uiImage
    }

    public var body: some View {
        Group {
            if wordImages != nil {
                Color.clear
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
            Button("OK") {}
        }
        .task {
            do {
                wordImages = try await analyzerService.analyzeImage(uiImage)
            } catch let error as KALocalizedError {
                self.error = error
                wordImages = []
            } catch {
                self.error = KALocalizedError.wrapping(error)
                wordImages = []
            }
        }
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
        Preview(shouldFail: true)
    }
#endif
