import Foundation
import SwiftData

@Model
public final class KAPhraseWordImage {
    @Attribute(.unique) public private(set) var id: UUID
    @Relationship(deleteRule: .cascade, inverse: \KAPhrase.wordImageRelations) public private(set) var phrase: KAPhrase
    @Relationship(deleteRule: .nullify, inverse: \KAWordImage.phraseRelations) public private(set) var wordImage: KAWordImage
    public private(set) var order: Int

    public init(id: UUID = .init(), phrase: KAPhrase, wordImage: KAWordImage, order: Int) {
        self.id = id
        self.phrase = phrase
        self.wordImage = wordImage
        self.order = order
    }
}
