import Foundation
import SwiftData

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
