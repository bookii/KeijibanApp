import Foundation
import KeijibanCommonModule

public struct KABoard: Decodable, Identifiable {
    public let id: UUID
    public let name: String
    public let index: Int

    public init(id: UUID, name: String, index: Int) {
        self.id = id
        self.name = name
        self.index = index
    }

    public init(from kcmBoardDTO: KCMBoardDTO) throws {
        guard let id = kcmBoardDTO.id else {
            throw KAError("id should not be nil")
        }
        self.id = id
        name = kcmBoardDTO.name
        index = kcmBoardDTO.index
    }
}
