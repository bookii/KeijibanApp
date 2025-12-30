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

        let storedBoards: [KABoard]

        do {
            storedBoards = try context.fetch(FetchDescriptor<KABoard>())
        } catch {
            throw KALocalizedError.withMessage("Failed to get stored board")
        }

        let storedBoardIds = Set(storedBoards.map(\.id))
        for fetchedBoard in fetchedBoards {
            if storedBoardIds.contains(fetchedBoard.id),
               let storedBoard = context.model(for: fetchedBoard.id) as? KABoard
            {
                storedBoard.update(with: fetchedBoard)
            } else {
                context.insert(fetchedBoard)
            }
            if context.hasChanges {
                try context.save()
            }
        }

        let fetchedBoardIds = Set(fetchedBoards.map(\.id))
        for storedBoard in storedBoards {
            if !fetchedBoardIds.contains(storedBoard.id) {
                storedBoard.delete()
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
