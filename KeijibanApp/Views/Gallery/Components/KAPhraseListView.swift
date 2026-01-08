import SwiftData
import SwiftUI

public struct KAPhraseListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var phrases: [KAPhrase]

    private var phrasesByDate: [(Date, [KAPhrase])] {
        let dict = Dictionary(grouping: phrases) { phrase in
            Calendar.current.startOfDay(for: phrase.createdAt)
        }
        return dict.sorted { $0.key > $1.key }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if !phrases.isEmpty {
                    List {
                        ForEach(phrasesByDate, id: \.0) { date, phrases in
                            Section(header: Text(date.formatted(date: .numeric, time: .omitted)).font(.kiyosuna(size: 16, weight: .bold))) {
                                ForEach(phrases.sorted { $0.createdAt > $1.createdAt }) { phrase in
                                    KAPhrasedWordImagesView(wordImages: phrase.wordImages)
                                }
                            }
                        }
                    }
                } else {
                    Text("作成したフレーズはありません")
                        .offset(y: -8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.kaSkyBlue)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("作成したフレーズ")
                        .font(.kiyosuna(size: 24, weight: .bold))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("X")
                            .font(.stick(size: 20))
                            .frame(width: 20, height: 20)
                            .offset(y: -2)
                    }
                    .buttonBorderShape(.circle)
                }
            }
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
