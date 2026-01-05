import Foundation
import KeijibanCommonModule

public struct KAEntry: Identifiable {
    public struct WordImage: Identifiable {
        public let id: UUID
        public let imageData: Data
    }

    public let id: UUID
    public let boardId: UUID
    public let wordImages: [WordImage]
    public let authorName: String
    public let likeCount: Int
    public let createdAt: Int

    public init(id: UUID, boardId: UUID, wordImages: [WordImage], authorName: String, likeCount: Int, createdAt: Int) {
        self.id = id
        self.boardId = boardId
        self.wordImages = wordImages
        self.authorName = authorName
        self.likeCount = likeCount
        self.createdAt = createdAt
    }

    public init(from kcmEntryDTO: KCMEntryDTO) throws {
        guard let id = kcmEntryDTO.id else {
            throw KALocalizedError.withMessage("id should not be nil")
        }
        guard let likeCount = kcmEntryDTO.likeCount else {
            throw KALocalizedError.withMessage("likeCount should not be nil")
        }
        guard let createdAt = kcmEntryDTO.createdAt else {
            throw KALocalizedError.withMessage("createdAt should not be nil")
        }
        var wordImages: [WordImage] = []
        for wordImage in kcmEntryDTO.wordImages {
            guard let wordImageId = wordImage.id else {
                throw KALocalizedError.withMessage("wordImage.id should not be nil")
            }
            guard let imageData = Data(base64Encoded: wordImage.base64EncodedImage) else {
                throw KALocalizedError.withMessage("base64EncodedImage should not be nil")
            }
            wordImages.append(.init(id: wordImageId, imageData: imageData))
        }

        self.id = id
        boardId = kcmEntryDTO.boardId
        self.wordImages = wordImages
        authorName = kcmEntryDTO.authorName
        self.likeCount = likeCount
        self.createdAt = createdAt
    }
}

public extension KAEntry {
    #if DEBUG
        static func mockEntry() async -> Self {
            let mockWordImages = await KAWordImage.mockWordImages()
            return .init(id: .init(), boardId: .init(), wordImages: mockWordImages.map { .init(id: $0.id, imageData: $0.imageData) },
                         authorName: "投稿者名", likeCount: 0, createdAt: Int(Date.now.timeIntervalSince1970))
        }
    #endif
}
