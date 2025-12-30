import Foundation
import SwiftData
import UIKit

@Model
public final class KAStoredWordImage: Identifiable, Sendable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var text: String
    public private(set) var imageData: Data

    public init(id: UUID, text: String, imageData: Data) {
        self.id = id
        self.text = text
        self.imageData = imageData
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
                return .init(id: .init(), text: $0.text, imageData: imageData)
            }
        }
    #endif
}
