import SwiftUI

public struct KAPhrasedWordImagesView: View {
    private let wordImages: [KAWordImage]

    public init(wordImages: [KAWordImage]) {
        self.wordImages = wordImages
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                // 同じ wordImage が複数含まれている場合があるので、offset を ID にする
                ForEach(wordImages.enumerated(), id: \.offset) { index, wordImage in
                    KALazyImageView(data: wordImage.imageData)
                        .frame(height: 48)
                        .frame(maxWidth: 72)
                }
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
