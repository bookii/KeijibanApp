import Foundation
import UIKit

public struct KAAnalyzeData {
    public struct WordImage: Hashable {
        public let text: String
        public let storedImage: UIImage
        public let previewImage: UIImage
        public let originInOriginalImage: CGPoint
    }

    public let originalImage: UIImage
    public let wordImages: [WordImage]
}

public extension KAAnalyzeData {
    #if DEBUG
        static func mockAnalyzePreviewData() async -> Self {
            await .init(originalImage: UIImage.mockImage(), wordImages: KAAnalyzeData.WordImage.mockWordImages())
        }
    #endif
}

public extension KAAnalyzeData.WordImage {
    #if DEBUG
        private struct UnfetchedWordImage {
            let text: String
            let imageURL: URL
            let origin: CGPoint
        }

        private nonisolated(unsafe) static var _mockWordImages: [Self]?

        static func mockWordImages() async -> [Self] {
            if let _mockWordImages {
                return _mockWordImages
            }

            let unfetchedWordImages: [UnfetchedWordImage] = [
                .init(text: "コメント", imageURL: .init(string: "https://i.gyazo.com/9d49450a3a24b0e7bf1ac1617c577bb0.png")!, origin: .init(x: 0, y: 0)),
                .init(text: "ほぼ", imageURL: .init(string: "https://i.gyazo.com/74a97a6d90825636b2ee1a49b1d2e8e3.png")!, origin: .init(x: 100, y: 0)),
                .init(text: "全部", imageURL: .init(string: "https://i.gyazo.com/e94048ab44be8f17ef37a60e9581dd29.png")!, origin: .init(x: 0, y: 100)),
                .init(text: "読みます", imageURL: .init(string: "https://i.gyazo.com/323175cb4113ff92e930b9f1a6c93ab5.png")!, origin: .init(x: 100, y: 100)),
            ]

            var wordImages: [Self] = []
            for unfetchedWordImage in unfetchedWordImages {
                do {
                    if let uiImage = try await UIImage(url: unfetchedWordImage.imageURL) {
                        wordImages.append(.init(text: unfetchedWordImage.text,
                                                storedImage: uiImage,
                                                previewImage: uiImage,
                                                originInOriginalImage: unfetchedWordImage.origin))
                    }
                } catch {
                    continue
                }
            }
            _mockWordImages = wordImages
            return wordImages
        }
    #endif
}
