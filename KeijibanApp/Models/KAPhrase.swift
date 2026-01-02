import Foundation
import SwiftData

@Model
public final class KAPhrase {
    @Attribute(.unique) public private(set) var id: UUID
    @Relationship(deleteRule: .cascade) public private(set) var wordImageRelations: [KAPhraseWordImage] = []
    public private(set) var text: String
    public private(set) var boards: [KABoard]
    public private(set) var createdAt: Date

    public var wordImages: [KAWordImage] {
        wordImageRelations
            .sorted { $0.order < $1.order }
            .compactMap(\.wordImage)
    }

    public init(id: UUID = .init(), wordImages: [KAWordImage], createdAt: Date = .now) {
        self.id = id
        text = wordImages.map(\.text).joined()
        boards = Array(Set(wordImages.map(\.board)))
        self.createdAt = createdAt
        wordImageRelations = wordImages.enumerated().map { index, wordImage in
            .init(phrase: self, wordImage: wordImage, order: index)
        }
    }
}

public extension KAPhrase {
    #if DEBUG
        static func mockPhrase() async -> KAPhrase {
            await .init(id: .init(), wordImages: KAWordImage.mockWordImages())
        }
    #endif
}
