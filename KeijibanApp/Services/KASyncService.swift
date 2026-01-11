import Foundation
import SwiftData
import SwiftUI

public extension EnvironmentValues {
    @Entry var syncService: KASyncServiceProtocol = KASyncService.shared
}

@MainActor
public protocol KASyncServiceProtocol {
    func syncBoards(_ boards: [KABoard]) throws
}

public final class KASyncService: KASyncServiceProtocol {
    public static let shared = KASyncService()

    private init() {}

    public func syncBoards(_ fetchedBoards: [KABoard]) throws {
        let context = ModelContext(ModelContainer.shared)
        let storedBoards: [KABoard]

        do {
            storedBoards = try context.fetch(FetchDescriptor<KABoard>())
        } catch {
            throw KALocalizedError.withMessage("Failed to get stored board")
        }

        for fetchedBoard in fetchedBoards {
            if let storedBoard = storedBoards.first(where: { $0.id == fetchedBoard.id }) {
                storedBoard.update(with: fetchedBoard)
            } else {
                context.insert(fetchedBoard)
            }
        }

        let fetchedBoardIds = Set(fetchedBoards.map(\.id))
        for storedBoard in storedBoards {
            if !fetchedBoardIds.contains(storedBoard.id) {
                storedBoard.delete()
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }
}

#if DEBUG
    public final class KAMockSyncService: KASyncServiceProtocol {
        public static let shared = KAMockSyncService()

        private init() {}

        public func syncBoards(_: [KABoard]) throws {}
    }
#endif
