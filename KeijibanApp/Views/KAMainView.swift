import SwiftUI

public struct KAMainView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab {
                KAIndexView()
            }
            Tab {
                KAKeijibanIndexView()
            }
        }
        .tabViewStyle(.page)
    }
}

#if DEBUG
    #Preview {
        KAMainView()
            .environment(\.apiService, KAMockApiService.shared)
    }
#endif
