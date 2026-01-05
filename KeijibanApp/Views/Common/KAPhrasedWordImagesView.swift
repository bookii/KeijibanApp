import SwiftUI

public struct KAPhrasedWordImagesView: View {
    private let wordImages: [KAWordImage]
    @State private var isInitiallyLoaded: Bool = false

    public init(wordImages: [KAWordImage]) {
        self.wordImages = wordImages
    }

    public var body: some View {
        if !wordImages.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    // 同じ wordImage が複数含まれている場合があるので、offset を ID にする
                    ForEach(wordImages.enumerated(), id: \.offset) { _, wordImage in
                        KALazyImageView(data: wordImage.imageData)
                            .frame(height: 48)
                            .frame(maxWidth: 72)
                    }
                }
            }
            .scrollIndicators(.never)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .defaultScrollAnchor(isInitiallyLoaded ? .trailing : nil, for: .sizeChanges)
            .onAppear {
                isInitiallyLoaded = true
            }
        } else {
            Color.clear
                .frame(height: 48)
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockWordImages: [KAWordImage]?
        if let mockWordImages {
            KAPhrasedWordImagesView(wordImages: mockWordImages)
        } else {
            Color.clear
                .task {
                    mockWordImages = await KAPhrase.mockPhrase().wordImages
                }
        }
    }
#endif
