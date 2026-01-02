import SwiftUI

public struct KALazyImageView: View {
    private let data: Data
    @State private var uiImage: UIImage?

    public init(data: Data) {
        self.data = data
    }

    public var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .onAppear {
            if uiImage == nil {
                Task {
                    let uiImage = await Task.detached(priority: .userInitiated) {
                        UIImage(data: data)
                    }.value
                    await MainActor.run {
                        self.uiImage = uiImage
                    }
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockImageData: Data?
        if let mockImageData {
            KALazyImageView(data: mockImageData)
        } else {
            Color.clear
                .task {
                    mockImageData = await KAWordImage.mockWordImages().first!.imageData
                }
        }
    }
#endif
