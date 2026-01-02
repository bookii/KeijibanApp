import SwiftData
import SwiftUI

public struct KAPhraseListView: View {
    @Query private var phrases: [KAPhrase]

    private var phrasesByDate: [(Date, [KAPhrase])] {
        let dict = Dictionary(grouping: phrases) { phrase in
            Calendar.current.startOfDay(for: phrase.createdAt)
        }
        return dict.sorted { $0.key > $1.key }
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(phrasesByDate, id: \.0) { date, phrases in
                    Section(date.formatted(date: .numeric, time: .omitted)) {
                        ForEach(phrases.sorted { $0.createdAt > $1.createdAt }) { phrase in
                            KAPhrasedWordImagesView(wordImages: phrase.wordImages)
                        }
                    }
                }
            }
            .navigationTitle("作成したフレーズ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockContainer: ModelContainer?
        if let mockContainer {
            KAPhraseListView()
                .modelContainer(mockContainer)
        } else {
            Color.clear
                .task {
                    mockContainer = await ModelContainer.mockContainer()
                }
        }
    }
#endif
