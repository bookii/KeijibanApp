import Alamofire
import Foundation
import KeijibanCommonModule
import SwiftUI

public extension EnvironmentValues {
    @Entry var apiService: KAApiServiceProtocol = KAApiService.shared
}

@MainActor
public protocol KAApiServiceProtocol {
    func fetchBoards(withEntries: Bool) async throws -> [KAFetchedBoard]
    func postEntry(boardId: UUID, wordImages: [KAWordImage], authorName: String, deleteKey: String) async throws
}

public final class KAApiService: KAApiServiceProtocol {
    public static let shared = KAApiService()
    private var apiBaseURL: URL {
        guard let apiBaseURLString = ProcessInfo.processInfo.environment["API_BASE_URL"] else {
            fatalError("API_BASE_URL is not set")
        }
        guard let apiBaseURL = URL(string: apiBaseURLString) else {
            fatalError("API_BASE_URL is invalid")
        }
        return apiBaseURL
    }

    private init() {}

    public func fetchBoards(withEntries: Bool) async throws -> [KAFetchedBoard] {
        let url = apiBaseURL.appendingPathComponent("/boards")
        return try await AF.request(url.absoluteString, parameters: KCMGetBoardsRequestQuery(withEntries: withEntries))
            .serializingDecodable([KCMBoardDTO].self)
            .value
            .map { try KAFetchedBoard(from: $0) }
    }

    public func postEntry(boardId: UUID, wordImages: [KAWordImage], authorName: String, deleteKey: String) async throws {
//        guard !authorName.isEmpty else {
//            throw KALocalizedError.withMessage("authorName must not be empty")
//        }
//        guard !deleteKey.isEmpty else {
//            throw KALocalizedError.withMessage("deleteKey must not be empty")
//        }
        let url = apiBaseURL.appendingPathComponent("/boards/\(boardId)/entries")
        let base64EncodedImages: [String] = wordImages.compactMap { wordImage in
            UIImage(data: wordImage.imageData)?.resized(toFit: .init(width: 72, height: 48))?.jpegData(compressionQuality: 0.3)?.base64EncodedString()
        }
        let requestBody = KCMPostEntriesRequestBody(
            wordImages: base64EncodedImages.enumerated().map { index, base64EncodedImage in
                .init(base64EncodedImage: base64EncodedImage, index: index)
            },
            authorName: authorName,
            deleteKey: deleteKey,
        )
        _ = try await AF.request(url.absoluteString, method: .post, parameters: requestBody, encoder: .json)
            .serializingDecodable(Empty.self, emptyResponseCodes: Set(200 ..< 300))
            .value
    }
}

#if DEBUG
    public final class KAMockApiService: KAApiServiceProtocol {
        private var shouldFail: Bool = false

        public init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        public func fetchBoards(withEntries _: Bool) async throws -> [KAFetchedBoard] {
            try await Task.sleep(for: .seconds(1))
            if shouldFail {
                throw KALocalizedError.withMessage("Mock Failure")
            }
            return await KAFetchedBoard.mockFetchedBoards()
        }

        public func postEntry(boardId _: UUID, wordImages _: [KAWordImage], authorName _: String, deleteKey _: String) async throws {}
    }
#endif
