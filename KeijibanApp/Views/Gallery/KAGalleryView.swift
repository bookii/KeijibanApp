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

    private static let spacing: CGFloat = 12
    private static let startDate = Date()
    private static let displayedWordCount: Int = 100
    private static let filterAllId = UUID()
    @Query private var allWordImages: [KAWordImage]
    @Query private var boards: [KABoard]
    @State private var selectedFilterId: UUID = filterAllId
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: IdentifiableImage?
    @State private var isPhraseListViewPresented: Bool = false
    @State private var shuffledWordImages: [KAWordImage] = []
    @State private var selectedWordImages: [KAWordImage] = []
    @State private var isSaveCompletionAlertPresented: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ContentView(wordImages: shuffledWordImages,
                            columnCount: max(1, Int(proxy.size.width / 100)),
                            selectedWordImages: $selectedWordImages)
                    .ignoresSafeArea()
                    .environment(\.onSelectWordImage) { wordImage in
                        selectedWordImages.append(wordImage)
                    }
            }
            .padding(.horizontal, 12)
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
                    SelectedImagesView(selectedImages: $selectedWordImages)
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
                        Section {
                            Button("", systemImage: "shuffle") {}
                        }
                        Section("フィルタ") {
                            Picker("", selection: $selectedFilterId) {
                                Text("すべて")
                                    .tag(Self.filterAllId)
                                ForEach(boards) { board in
                                    Text(board.name)
                                        .tag(board.id.uuidString)
                                }
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
            .onAppear {
                shuffledWordImages = Array(allWordImages.shuffled().prefix(Self.displayedWordCount))
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
        @Binding private var selectedImages: [KAWordImage]

        fileprivate init(selectedImages: Binding<[KAWordImage]>) {
            _selectedImages = selectedImages
        }

        fileprivate var body: some View {
            VStack(spacing: 8) {
                KAPhrasedWordImagesView(wordImages: selectedImages)
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
                        selectedImages = []
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    Button {
                        modelContext.insert(KAPhrase(wordImages: selectedImages))
                        onSavePhrase?()
                        selectedImages = []
                    } label: {
                        Text("フレーズを保存する")
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
