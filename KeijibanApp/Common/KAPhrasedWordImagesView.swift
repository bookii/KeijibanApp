import SwiftUI

public struct KAPhrasedWordImagesView: View {
    private let wordImages: [KAStoredWordImage]

    public init(wordImages: [KAStoredWordImage]) {
        self.wordImages = wordImages
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(wordImages) { wordImage in
                    KALazyImageView(data: wordImage.imageData)
                        .frame(height: 48)
                        .frame(maxWidth: 72)
                }
            }
        }
        .scrollIndicators(.never)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .defaultScrollAnchor(.trailing, for: .sizeChanges)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockWordImages: [KAStoredWordImage]?
        if let mockWordImages {
            KAPhrasedWordImagesView(wordImages: mockWordImages)
        } else {
            Color.clear
                .task {
                    mockWordImages = await KAPhrase.mockPhrase().storedWordImages
                }
        }
    }
#endif
