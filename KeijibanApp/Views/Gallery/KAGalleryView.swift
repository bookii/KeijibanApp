import PhotosUI
import SwiftData
import SwiftUI

private extension EnvironmentValues {
    @Entry var onSelectWordImage: ((KAWordImage) -> Void)?
    @Entry var onSavePhrase: (() -> Void)?
}

public struct KAGalleryView: View {
    private struct IdentifiableImage: Identifiable {
        let id: UUID = .init()
        let uiImage: UIImage

        init(_ uiImage: UIImage) {
            self.uiImage = uiImage
        }
    }

    private enum Filter: Hashable {
        case all
        case board(UUID)
    }

    private static let spacing: CGFloat = 12
    private static let startDate = Date()
    private static let displayedWordCount: Int = 100
    private static let selectedWordImagesLimit: Int = 10
    @Environment(\.modelContext) private var modelContext
    @Query private var boards: [KABoard]
    @State private var selectedFilter: Filter = .all
    @State private var filteredWordImages: [KAWordImage] = []
    @State private var selectedWordImages: [KAWordImage] = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: IdentifiableImage?
    @State private var isPhraseListViewPresented: Bool = false
    @State private var isSaveCompletionAlertPresented: Bool = false
    @State private var error: Error?
    private var isSelectedWordImagesFull: Bool {
        selectedWordImages.count >= KAGalleryView.selectedWordImagesLimit
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ContentView(wordImages: filteredWordImages,
                            columnCount: max(1, Int(proxy.size.width / 100)),
                            selectedWordImages: $selectedWordImages)
                    .ignoresSafeArea()
                    .environment(\.onSelectWordImage) { wordImage in
                        if !isSelectedWordImagesFull {
                            selectedWordImages.append(wordImage)
                        }
                    }
            }
            .padding(.horizontal, 12)
            .errorAlert($error)
            .sheet(item: $pickedImage) {
                pickedImage = nil
            } content: { pickedImage in
                KAAnalyzerView(uiImage: pickedImage.uiImage)
            }
            .sheet(isPresented: $isPhraseListViewPresented) {
                KAPhraseListView()
            }
            .overlay(alignment: .bottom) {
                if !selectedWordImages.isEmpty {
                    SelectedImagesView(selectedWordImages: $selectedWordImages)
                        .padding(16)
                        .environment(\.onSavePhrase) {
                            isSaveCompletionAlertPresented = true
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemImage: "book.pages") {
                        isPhraseListViewPresented = true
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("", systemImage: "line.3.horizontal.decrease") {
                        Picker("", selection: $selectedFilter) {
                            Text("すべて")
                                .tag(Filter.all)
                            ForEach(boards) { board in
                                Text(board.name)
                                    .tag(Filter.board(board.id))
                            }
                        }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("", systemImage: "plus")
                    }
                }
            }
            .alert("フレーズを保存しました！", isPresented: $isSaveCompletionAlertPresented) {
                Button("OK") {}
            }
            .task(id: selectedFilter) {
                await fetchWordImages()
            }
            .onChange(of: pickerItem) {
                guard let pickerItem else {
                    return
                }
                pickerItem.loadTransferable(type: Data.self) { result in
                    Task { @MainActor in
                        if pickerItem == self.pickerItem,
                           case let .success(data) = result,
                           let uiImage = data.flatMap({ UIImage(data: $0) })
                        {
                            pickedImage = IdentifiableImage(uiImage)
                        }
                    }
                }
            }
        }
    }

    private struct SelectedImagesView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.onSavePhrase) private var onSavePhrase
        @Binding private var selectedWordImages: [KAWordImage]

        fileprivate init(selectedWordImages: Binding<[KAWordImage]>) {
            _selectedWordImages = selectedWordImages
        }

        fileprivate var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    KAPhrasedWordImagesView(wordImages: selectedWordImages)
                    Text("\(selectedWordImages.count)/\(KAGalleryView.selectedWordImagesLimit)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background {
                    Color(.systemGray6)
                        .clipShape(.capsule)
                        .glassEffect()
                }
                .background(in: Capsule())
                HStack(spacing: 6) {
                    Button {
                        selectedWordImages = []
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    Button {
                        modelContext.insert(KAPhrase(wordImages: selectedWordImages))
                        onSavePhrase?()
                        selectedWordImages = []
                    } label: {
                        Text("フレーズを作成する")
                            .frame(height: 32)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private struct ContentView: View {
        private let wordImagesInColumns: [[KAWordImage]]
        private var columnCount: Int {
            wordImagesInColumns.count
        }

        fileprivate init(wordImages: [KAWordImage], columnCount: Int, selectedWordImages _: Binding<[KAWordImage]>) {
            var wordImagesInColumns = Array(repeating: [KAWordImage](), count: columnCount)
            for index in wordImages.indices {
                wordImagesInColumns[index % columnCount].append(wordImages[index])
            }
            self.wordImagesInColumns = wordImagesInColumns
        }

        fileprivate var body: some View {
            HStack(alignment: .top, spacing: KAGalleryView.spacing) {
                ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                    ColumnView(wordImages: wordImagesInColumns[columnIndex])
                }
            }
        }
    }

    private struct ColumnView: View {
        private let wordImages: [KAWordImage]
        @Environment(\.onSelectWordImage) private var onSelectWordImage
        @State private var rowCount = KAGalleryView.displayedWordCount
        @State private var viewWidth: CGFloat?

        fileprivate init(wordImages: [KAWordImage]) {
            self.wordImages = wordImages
        }

        fileprivate var body: some View {
            TimelineView(.animation) { context in
                if !wordImages.isEmpty {
                    let elapsedTime = context.date.timeIntervalSince(KAGalleryView.startDate)
                    ScrollView {
                        LazyVStack(spacing: KAGalleryView.spacing) {
                            ForEach(0 ..< rowCount, id: \.self) { rowIndex in
                                let wordImage = wordImages[rowIndex % wordImages.count]
                                Button {
                                    onSelectWordImage?(wordImage)
                                } label: {
                                    KALazyImageView(data: wordImage.imageData)
                                        .frame(maxWidth: .infinity, maxHeight: viewWidth.flatMap { $0 * 1.5 }, alignment: .center)
                                        .id(wordImage.id)
                                        .onAppear {
                                            if rowIndex == rowCount - 1 {
                                                rowCount = rowCount + wordImages.count
                                            }
                                        }
                                        .rotationEffect(.degrees(180))
                                }
                            }
                        }
                        .offset(y: -elapsedTime * 100)
                        .background(Color(.systemBackground))
                    }
                    .scrollIndicators(.never)
                    .scrollEdgeEffectStyle(.none, for: .all)
                    .scrollEdgeEffectHidden(true)
                    .scrollDisabled(true)
                }
            }
            .rotationEffect(.degrees(180))
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
                viewWidth = width
            }
        }
    }

    private func fetchWordImages() async {
        let predicate: Predicate<KAWordImage>
        switch selectedFilter {
        case .all:
            predicate = #Predicate { _ in true }
        case let .board(id):
            predicate = #Predicate { $0.board.id == id }
        }
        var descriptor = FetchDescriptor<KAWordImage>(predicate: predicate)
        descriptor.fetchLimit = Self.displayedWordCount
        do {
            filteredWordImages = try modelContext.fetch(descriptor)
        } catch {
            self.error = error
            filteredWordImages = []
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var mockContainer: ModelContainer?
        if let mockContainer {
            KAGalleryView()
                .modelContainer(mockContainer)
        } else {
            Color.clear
                .task {
                    mockContainer = await ModelContainer.mockContainer()
                }
        }
    }
#endif
