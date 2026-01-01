import Foundation
import SwiftData

@Model
public final class KAPhrase {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var storedWordImages: [KAStoredWordImage]
    public private(set) var text: String
    public private(set) var createdAt: Date

    public init(id: UUID, storedWordImages: [KAStoredWordImage]) {
        self.id = id
        self.storedWordImages = storedWordImages
        text = storedWordImages.map(\.text).joined()
        createdAt = .now
    }
}
