import Foundation

public struct KAError: LocalizedError {
    public let errorDescription: String?

    public init(_ errorDescription: String?) {
        self.errorDescription = errorDescription
    }
}
