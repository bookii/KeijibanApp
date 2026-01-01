import Foundation
import SwiftData

@Model
public final class KASentence {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var storedWordImages: [KAStoredWordImage]

    public init(id: UUID, storedWordImages: [KAStoredWordImage]) {
        self.id = id
        self.storedWordImages = storedWordImages
    }
}
