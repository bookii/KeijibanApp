import Foundation
import KeijibanCommonModule

public struct KABoard: Codable {
    public let id: UUID?
    public let name: String
    public let index: Int

    public init(id: UUID?, name: String, index: Int) {
        self.id = id
        self.name = name
        self.index = index
    }

    public init(from decoder: any Decoder) throws {
        let kcmBoardDTO = try KCMBoardDTO(from: decoder)
        id = kcmBoardDTO.id
        name = kcmBoardDTO.name
        index = kcmBoardDTO.index
    }

    public func encode(to encoder: any Encoder) throws {
        try KCMBoardDTO(id: id, name: name, index: index).encode(to: encoder)
    }
}
