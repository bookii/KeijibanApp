import Foundation
import SwiftData

public extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try .init(for: KABoard.self, KAWordImage.self, KAPhrase.self, KAPhraseWordImage.self,
                             configurations: ModelConfiguration(isStoredInMemoryOnly: false))
        } catch {
            fatalError("Failed to init modelContainer: \(error.localizedDescription)")
        }
    }()

    #if DEBUG
        static func mockContainer() async -> ModelContainer {
            do {
                let container = try ModelContainer(for: KABoard.self, KAWordImage.self, KAPhrase.self, KAPhraseWordImage.self,
                                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                for board in KABoard.mockBoards {
                    container.mainContext.insert(board)
                }
                let wordImages = await KAWordImage.mockWordImages()
                for wordImage in wordImages {
                    container.mainContext.insert(wordImage)
                }
                let dates: [Date] = [.now, .now, .init(timeIntervalSinceNow: -60 * 60 * 24)]
                for date in dates {
                    container.mainContext.insert(KAPhrase(wordImages: wordImages, createdAt: date))
                }
                return container
            } catch {
                fatalError("Failed to init modelContainer: \(error.localizedDescription)")
            }
        }
    #endif
}
