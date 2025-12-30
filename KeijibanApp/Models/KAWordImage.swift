import Foundation
import SwiftData
import UIKit

@Model
public final class KAWordImage: Identifiable, Sendable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var text: String
    public private(set) var imageData: Data

    public init(id: UUID, text: String, imageData: Data) {
        self.id = id
        self.text = text
        self.imageData = imageData
    }
}

public extension KAWordImage {
    #if DEBUG
        private struct UnstructuredWord {
            let text: String
            let imageURL: URL
        }

        private nonisolated(unsafe) static var _mockWordImages: [KAWordImage]?

        static func mockWordImages() async -> [KAWordImage] {
            if let _mockWordImages {
                return _mockWordImages
            }

            let unstructuredWords: [UnstructuredWord] = [
                .init(text: "コメント", imageURL: .init(string: "https://i.gyazo.com/9d49450a3a24b0e7bf1ac1617c577bb0.png")!),
                .init(text: "ほぼ", imageURL: .init(string: "https://i.gyazo.com/74a97a6d90825636b2ee1a49b1d2e8e3.png")!),
                .init(text: "全部", imageURL: .init(string: "https://i.gyazo.com/e94048ab44be8f17ef37a60e9581dd29.png")!),
                .init(text: "読みます", imageURL: .init(string: "https://i.gyazo.com/323175cb4113ff92e930b9f1a6c93ab5.png")!),
            ]
            var wordImages: [KAWordImage] = []
            for index in unstructuredWords.indices {
                let unstructuredWord = unstructuredWords[index]

                do {
                    if let image = try await UIImage(url: unstructuredWord.imageURL), let imageData = image.jpegData(compressionQuality: 0.9) {
                        wordImages.append(.init(id: UUID(), text: unstructuredWord.text, imageData: imageData))
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
