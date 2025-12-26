import Foundation
import KeijibanCommonModule
import SwiftUI

public extension EnvironmentValues {
    @Entry var apiService: KAApiServiceProtocol = KAApiService()
}

@MainActor
public protocol KAApiServiceProtocol {
    func fetchBoards() async throws -> [KABoard]
}

public final class KAApiService: KAApiServiceProtocol {
    public func fetchBoards() async throws -> [KABoard] {
        []
    }
}

public final class KAMockApiService: KAApiServiceProtocol {
    public func fetchBoards() async throws -> [KABoard] {
        try await Task.sleep(for: .seconds(1))
        return [
            .init(id: .init(uuidString: "bec571c3-688e-0809-6016-f72b5f616599"), name: "新聞・雑誌部", index: 0),
            .init(id: .init(uuidString: "c31feb82-21ea-6dda-bdc7-7e2f6f01d369"), name: "手書き部", index: 1),
            .init(id: .init(uuidString: "4779bc64-d847-efc5-c03a-b8b137ae5af0"), name: "風景部", index: 2),
            .init(id: .init(uuidString: "19e6655c-d191-54a6-c4af-6395cbcf4b1e"), name: "作字部", index: 3),
            .init(id: .init(uuidString: "e1205869-830b-a243-d96f-3cb141286458"), name: "フリースタイル部", index: 4),
        ]
    }
}
