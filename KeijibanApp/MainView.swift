import SwiftUI

public struct MainView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab {
                IndexView()
            }
            Tab {
                EmptyView()
            }
        }
        .tabViewStyle(.page)
    }
}

#if DEBUG
#Preview {
    MainView()
}
#endif
