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
        id = board.id
        name = board.name
        index = board.index
        isDeleted = false
    }

    public func delete() {
        isDeleted = true
    }
}
