import Foundation
import SwiftData
import SwiftUI

public extension EnvironmentValues {
    @Entry var syncService: KASyncServiceProtocol = KASyncService.shared
}

@MainActor
public protocol KASyncServiceProtocol {
    func syncBoards(fetchedBoards: [KABoard])
}

public final class KASyncService: KASyncServiceProtocol {
    public static let shared = KASyncService()

    private init() {}

    public func syncBoards(fetchedBoards: [KABoard]) {
        let context = ModelContext(ModelContainer.shared)

        for fetchedBoard in fetchedBoards {
            if let storedBoard = context.model(for: fetchedBoard.id) as? KABoard {
                storedBoard.update(with: fetchedBoard)
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
