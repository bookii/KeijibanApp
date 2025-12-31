import Foundation
import KeijibanCommonModule
import SwiftData

@Model
public class KABoard: Identifiable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var name: String
    public private(set) var index: Int
    public private(set) var isDeleted: Bool

    public init(id: UUID, name: String, index: Int, isDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.index = index
        self.isDeleted = isDeleted
    }

    public init(from kcmBoardDTO: KCMBoardDTO) throws {
        guard let id = kcmBoardDTO.id else {
            throw KALocalizedError.withMessage("id should not be nil")
        }
        self.id = id
        name = kcmBoardDTO.name
        index = kcmBoardDTO.index
        isDeleted = false
    }

    public func update(with board: KABoard) {
        guard id == board.id else {
            return
        }
        name = board.name
        index = board.index
        isDeleted = false
    }

    public func delete() {
        isDeleted = true
    }
}

#if DEBUG
    public extension KABoard {
        static var mockBoards: [KABoard] {
            [
                .init(id: .init(uuidString: "bec571c3-688e-0809-6016-f72b5f616599")!, name: "新聞・雑誌部", index: 0),
                .init(id: .init(uuidString: "c31feb82-21ea-6dda-bdc7-7e2f6f01d369")!, name: "手書き部", index: 1),
                .init(id: .init(uuidString: "4779bc64-d847-efc5-c03a-b8b137ae5af0")!, name: "風景部", index: 2),
                .init(id: .init(uuidString: "19e6655c-d191-54a6-c4af-6395cbcf4b1e")!, name: "作字部", index: 3),
                .init(id: .init(uuidString: "e1205869-830b-a243-d96f-3cb141286458")!, name: "フリースタイル部", index: 4),
            ]
        }
    }
#endif
