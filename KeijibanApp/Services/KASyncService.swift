import Foundation
import SwiftData
import SwiftUI

public extension EnvironmentValues {
    @Entry var syncService: KASyncServiceProtocol = KASyncService.shared
}

@MainActor
public protocol KASyncServiceProtocol {
    func syncBoards(fetchedBoards: [KABoard]) throws
}

public final class KASyncService: KASyncServiceProtocol {
    public static let shared = KASyncService()

    private init() {}

    public func syncBoards(fetchedBoards: [KABoard]) throws {
        let context = ModelContext(ModelContainer.shared)

        for fetchedBoard in fetchedBoards {
            let fetchedBoardId = fetchedBoard.id
            do {
                if let storedBoard = try context.fetch(FetchDescriptor<KABoard>(predicate: #Predicate { $0.id == fetchedBoardId })).first {
                    storedBoard.update(with: fetchedBoard)
                } else {
                    context.insert(fetchedBoard)
                }
            } catch {
                throw KALocalizedError.withMessage("Failed to sync board: \(fetchedBoard.id)")
            }
        }
    }
}

#if DEBUG
    public final class KAMockSyncService: KASyncServiceProtocol {
        public static let shared = KAMockSyncService()

        private init() {}

        public func syncBoards(fetchedBoards _: [KABoard]) {}
    }
#endif
