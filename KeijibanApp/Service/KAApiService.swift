import Foundation
import SwiftUI

public extension EnvironmentValues {
    @Entry var apiService: KAApiServiceProtocol = KAMockApiService()
}

public protocol KAApiServiceProtocol {}

public final class KAMockApiService: KAApiServiceProtocol {}
