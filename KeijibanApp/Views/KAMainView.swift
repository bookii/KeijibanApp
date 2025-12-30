import SwiftUI

public struct KAMainView: View {
    @State private var selectedTabIndex: Int = 1

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab(value: 0) {
                KAStreamView()
            }
            Tab(value: 1) {
                KAIndexView()
            }
            Tab(value: 2) {
                KAKeijibanIndexView()
            }
        }
        .tabViewStyle(.page)
        .ignoresSafeArea()
    }
}

#if DEBUG
    #Preview {
        KAMainView()
            .environment(\.apiService, KAMockApiService())
            .environment(\.syncService, KAMockSyncService.shared)
    }
#endif
