import Foundation
import KeijibanCommonModule
import SwiftData

public struct KAFetchedBoard: Identifiable {
    public let board: KABoard
    public let entries: [KAEntry]

    public var id: UUID {
        board.id
    }

    public init(board: KABoard, entries: [KAEntry]) {
        self.board = board
        self.entries = entries
    }
}

public extension KAFetchedBoard {
    init(from kcmBoardDTO: KCMBoardDTO) throws {
        let board = try KABoard(from: kcmBoardDTO)
        let entries = try kcmBoardDTO.entries.map { try KAEntry(from: $0) }
        self.init(board: board, entries: entries)
    }

    #if DEBUG
        static func mockFetchedBoards() async -> [Self] {
            let mockEntry = await KAEntry.mockEntry()
            return KABoard.mockBoards().map { .init(board: $0, entries: Array(repeating: mockEntry, count: 5)) }
        }
    #endif
}
