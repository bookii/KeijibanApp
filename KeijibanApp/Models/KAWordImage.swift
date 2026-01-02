import Foundation
import SwiftData
import UIKit

@Model
public final class KAWordImage: Identifiable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var text: String
    public private(set) var imageData: Data
    @Relationship(deleteRule: .cascade) public private(set) var board: KABoard
    @Relationship(deleteRule: .cascade) public private(set) var phraseRelations: [KAPhraseWordImage] = []

    public init(id: UUID, text: String, imageData: Data, board: KABoard) {
        self.id = id
        self.text = text
        self.imageData = imageData
        self.board = board
    }

    public init(analyzedWordImage: KAAnalyzeData.WordImage, board: KABoard) throws {
        guard let imageData = analyzedWordImage.storedImage.jpegData(compressionQuality: 0.9) else {
            throw KALocalizedError.withMessage("Failed to convert UIImage to Data.")
        }
        id = .init()
        text = analyzedWordImage.text
        self.imageData = imageData
        self.board = board
    }
}

public extension KAWordImage {
    #if DEBUG
        private nonisolated(unsafe) static var _mockWordImages: [KAWordImage]?

        static func mockWordImages() async -> [KAWordImage] {
            if let _mockWordImages {
                return _mockWordImages
            }
            let mockWordImages: [KAWordImage] = await KAAnalyzeData.mockAnalyzePreviewData().wordImages.compactMap {
                guard let imageData = $0.storedImage.jpegData(compressionQuality: 0.9) else {
                    return nil
                }
                return .init(id: .init(), text: $0.text, imageData: imageData, board: .mockBoards.randomElement()!)
            }
            _mockWordImages = mockWordImages
            return mockWordImages
        }
    #endif
}
