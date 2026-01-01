import Foundation
import SwiftData

public extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try .init(for: KABoard.self, KAStoredWordImage.self, KAPhrase.self,
                             configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        } catch {
            fatalError("Failed to init modelContainer: \(error.localizedDescription)")
        }
    }()
}
