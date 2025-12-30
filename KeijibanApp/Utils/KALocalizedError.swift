import Foundation

public enum KALocalizedError: LocalizedError {
    case withMessage(String)
    case wrapping(Error)

    public var errorDescription: String? {
        switch self {
        case let .withMessage(message):
            message
        case let .wrapping(error):
            error.localizedDescription
        }
    }
}
