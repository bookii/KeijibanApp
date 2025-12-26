import SwiftUI

public struct KAMainView: View {
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
        KAMainView()
    }
#endif
