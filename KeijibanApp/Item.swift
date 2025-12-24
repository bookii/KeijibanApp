import Foundation
import SwiftData

@Model
public final class Item {
    public private(set) var timestamp: Date

    public init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
