import Foundation
import SwiftData
import UIKit

@Model
public final class KAStoredWordImage: Identifiable, Sendable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var text: String
    public private(set) var imageData: Data
    public private(set) var board: KABoard

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

public extension KAStoredWordImage {
    #if DEBUG
        private nonisolated(unsafe) static var _mockWordImages: [KAStoredWordImage]?

        static func mockWordImages() async -> [KAStoredWordImage] {
            await KAAnalyzeData.mockAnalyzePreviewData().wordImages.compactMap {
                guard let imageData = $0.storedImage.jpegData(compressionQuality: 0.9) else {
                    return nil
                }
                return .init(id: .init(), text: $0.text, imageData: imageData, board: .mockBoards.first!)
            }
        }
    #endif
}
