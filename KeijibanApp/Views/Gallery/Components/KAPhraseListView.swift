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
                        ForEach(phrases) { phrase in
                            KAPhrasedWordImagesView(wordImages: phrase.storedWordImages)
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
        @Previewable @State var modelContainer: ModelContainer?
        let dates: [Date] = [.now, .now, .init(timeIntervalSinceNow: -60 * 60 * 24)]
        if let modelContainer {
            KAPhraseListView()
                .modelContainer(modelContainer)
        } else {
            Color.clear
                .task {
                    let container: ModelContainer
                    do {
                        container = try ModelContainer(for: KAPhrase.self, configurations: .init(isStoredInMemoryOnly: true))
                    } catch {
                        fatalError("Failed to init modelContainer: \(error.localizedDescription)")
                    }
                    let mockPhrase = await KAPhrase.mockPhrase()
                    for date in dates {
                        container.mainContext.insert(KAPhrase(id: .init(), storedWordImages: mockPhrase.storedWordImages, createdAt: date))
                    }
                    modelContainer = container
                }
        }
    }
#endif
