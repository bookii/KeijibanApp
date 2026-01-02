import SwiftData
import SwiftUI

public struct KAPostView: View {
    @Binding private var isPresented: Bool
    @Query private var boards: [KABoard]
    @Query private var wordImages: [KAWordImage]
    @Query private var phrases: [KAPhrase]

    public init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    public var body: some View {
        NavigationStack {
            Text("")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("", systemImage: "xmark") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockContainer: ModelContainer?
        @Previewable @State var isPresented = false
        Color(.systemGray6)
            .ignoresSafeArea()
            .overlay {
                Button("表示する") {
                    isPresented = true
                }
                .disabled(mockContainer == nil)
            }
            .fullScreenCover(isPresented: $isPresented) {
                if let mockContainer {
                    KAPostView(isPresented: $isPresented)
                        .modelContainer(mockContainer)
                }
            }
            .task {
                mockContainer = await ModelContainer.mockContainer()
                try? await Task.sleep(for: .seconds(1))
                isPresented = true
            }
    }
#endif
