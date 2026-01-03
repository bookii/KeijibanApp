import Alamofire
import Foundation
import KeijibanCommonModule
import SwiftUI

public extension EnvironmentValues {
    @Entry var apiService: KAApiServiceProtocol = KAApiService.shared
}

@MainActor
public protocol KAApiServiceProtocol {
    func fetchBoards() async throws -> [KABoard]
    func postEntry(boardId: UUID, wordImages: [KAWordImage], authorName: String, deleteKey: String) async throws
}

public final class KAApiService: KAApiServiceProtocol {
    public static let shared = KAApiService()
    private var apiBaseURL: URL {
        guard let apiBaseURLString = ProcessInfo.processInfo.environment["API_BASE_URL"] else {
            fatalError("API_BASE_URL is not set")
        }
        guard let apiBaseURL = URL(string: apiBaseURLString) else {
            fatalError("API_BASE_URL is invalidn")
        }
        return apiBaseURL
    }

    private init() {}

    public func fetchBoards() async throws -> [KABoard] {
        try await AF.request(apiBaseURL.appendingPathComponent("/boards").absoluteString)
            .serializingDecodable([KCMBoardDTO].self)
            .value
            .map(KABoard.init(from:))
    }

    public func postEntry(boardId: UUID, wordImages: [KAWordImage], authorName: String, deleteKey: String) async throws {
        guard authorName.count > 0 else {
            throw KALocalizedError.withMessage("authorName must not be empty")
        }
        guard deleteKey.count > 0 else {
            throw KALocalizedError.withMessage("deleteKey must not be empty")
        }
        let base64EncodedStrings = wordImages.map { $0.imageData.base64EncodedString() }
        let url = apiBaseURL.appendingPathComponent("/boards/\(boardId)/entries")
        _ = try await AF.request(url.absoluteString, method: .post, parameters: [
            "word_images": base64EncodedStrings,
            "author_name": authorName,
            "delete_key": deleteKey,
        ])
        .serializingDecodable(EmptyResponse.self)
        .value
    }
}

private nonisolated struct EmptyResponse: Decodable, Sendable {}

#if DEBUG
    public final class KAMockApiService: KAApiServiceProtocol {
        private var shouldFail: Bool = false

        public init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        public func fetchBoards() async throws -> [KABoard] {
            try await Task.sleep(for: .seconds(1))
            if shouldFail {
                throw KALocalizedError.withMessage("Mock Failure")
            }
            return [
                .init(id: .init(uuidString: "bec571c3-688e-0809-6016-f72b5f616599")!, name: "新聞・雑誌部", index: 0),
                .init(id: .init(uuidString: "c31feb82-21ea-6dda-bdc7-7e2f6f01d369")!, name: "手書き部", index: 1),
                .init(id: .init(uuidString: "4779bc64-d847-efc5-c03a-b8b137ae5af0")!, name: "風景部", index: 2),
                .init(id: .init(uuidString: "19e6655c-d191-54a6-c4af-6395cbcf4b1e")!, name: "作字部", index: 3),
                .init(id: .init(uuidString: "e1205869-830b-a243-d96f-3cb141286458")!, name: "フリースタイル部", index: 4),
            ]
        }

        public func postEntry(boardId _: UUID, wordImages _: [KAWordImage], authorName _: String, deleteKey _: String) async throws {}
    }
#endif
