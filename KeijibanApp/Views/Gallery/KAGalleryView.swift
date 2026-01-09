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
            VStack(spacing: 16) {
                if !filteredWordImages.isEmpty {
                    GeometryReader { proxy in
                        ContentView(wordImages: filteredWordImages,
                                    rowCount: max(1, Int(proxy.size.height / 80)))
                            .environment(\.onSelectWordImage) { wordImage in
                                if !isSelectedWordImagesFull {
                                    selectedWordImages.append(wordImage)
                                }
                            }
                    }
                    SelectedImagesView(selectedWordImages: $selectedWordImages)
                        .padding(.horizontal, 16)
                        .environment(\.onSavePhrase) {
                            isSaveCompletionAlertPresented = true
                        }
                        .opacity(selectedWordImages.isEmpty ? 0 : 1)
                } else {
                    Text("+ボタンで写真を読み込んでみよう")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.vertical, 16)
            .ignoresSafeArea()
            .errorAlert($error)
            .sheet(item: $pickedImage) {
                pickedImage = nil
                Task {
                    await fetchWordImages()
                }
            } content: { pickedImage in
                KAAnalyzerView(uiImage: pickedImage.uiImage)
            }
            .sheet(isPresented: $isPhraseListViewPresented) {
                KAPhraseListView()
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 4) {
                    let font = Font.stick(size: 20)
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label {
                            Text("")
                        } icon: {
                            Text("十")
                                .font(font)
                                .frame(width: 20, height: 20)
                                .offset(y: -1)
                        }
                        .labelStyle(IconOnlyLabelStyle())
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                    Menu {
                        Picker("", selection: $selectedFilter) {
                            Text("すべて")
                                .tag(Filter.all)
                            ForEach(boards) { board in
                                Text(board.name)
                                    .tag(Filter.board(board.id))
                            }
                        }
                    } label: {
                        Text("Y")
                            .font(.stick(size: 20))
                            .frame(width: 20, height: 20)
                            .offset(y: -1)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                    Button {
                        isPhraseListViewPresented = true
                    } label: {
                        Text("図")
                            .font(.stick(size: 20))
                            .frame(width: 20, height: 20)
                            .offset(y: -1)
                    }
                    .buttonStyle(.glass)
                    .clipShape(.circle)
                }
                .offset(x: 24, y: 24)
                .ignoresSafeArea(edges: [.top, .leading])
            }
            .alert("フレーズを保存しました！", isPresented: $isSaveCompletionAlertPresented) {
                Button("OK") {}
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
            .onChange(of: selectedFilter) {
                Task {
                    await fetchWordImages()
                }
            }
            .onAppear {
                Task {
                    await fetchWordImages()
                }
            }
            .onDisappear {
                filteredWordImages.removeAll()
            }
            .background(Color.kaGalleryBackground)
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
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    KAPhrasedWordImagesView(wordImages: selectedWordImages)
                    Text("\(selectedWordImages.count)/\(KAGalleryView.selectedWordImagesLimit)")
                        .font(.kiyosuna(size: 14))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background {
                    Color(.clear)
                        .clipShape(.capsule)
                        .glassEffect()
                }
                Button {
                    modelContext.insert(KAPhrase(wordImages: selectedWordImages))
                    onSavePhrase?()
                    selectedWordImages = []
                } label: {
                    Text("フレーズを作成する")
                        .frame(height: 24)
                }
                .buttonStyle(.glassProminent)
                Button {
                    selectedWordImages = []
                } label: {
                    Text("X")
                        .font(.stick(size: 20))
                        .frame(width: 20, height: 20)
                        .offset(y: -2)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
        }
    }

    private struct ContentView: View {
        private let wordImagesInRows: [[KAWordImage]]
        private var rowCount: Int {
            wordImagesInRows.count
        }

        fileprivate init(wordImages: [KAWordImage], rowCount: Int) {
            var wordImagesInRows = Array(repeating: [KAWordImage](), count: rowCount)
            for index in wordImages.indices {
                wordImagesInRows[index % rowCount].append(wordImages[index])
            }
            self.wordImagesInRows = wordImagesInRows
        }

        fileprivate var body: some View {
            VStack(alignment: .leading, spacing: KAGalleryView.spacing) {
                ForEach(0 ..< rowCount, id: \.self) { columnIndex in
                    RowView(wordImages: wordImagesInRows[columnIndex])
                }
            }
        }
    }

    private struct RowView: View {
        private let wordImages: [KAWordImage]
        @Environment(\.onSelectWordImage) private var onSelectWordImage
        @State private var columnCount = KAGalleryView.displayedWordCount
        @State private var viewHeight: CGFloat?
        @State private var startDate = Date()

        fileprivate init(wordImages: [KAWordImage]) {
            self.wordImages = wordImages
        }

        fileprivate var body: some View {
            TimelineView(.animation) { context in
                if !wordImages.isEmpty {
                    let elapsedTime = context.date.timeIntervalSince(startDate)
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: KAGalleryView.spacing) {
                            ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                                let wordImage = wordImages[columnIndex % wordImages.count]
                                Button {
                                    onSelectWordImage?(wordImage)
                                } label: {
                                    KALazyImageView(data: wordImage.imageData)
                                        .frame(maxWidth: viewHeight.map { $0 * 1.5 }, maxHeight: .infinity, alignment: .center)
                                        .id(wordImage.id)
                                        .onAppear {
                                            if columnIndex == columnCount - 1 {
                                                columnCount = columnCount + wordImages.count
                                            }
                                        }
                                        .rotationEffect(.degrees(180))
                                        .padding(4)
                                        .background(Color.white)
                                        .shadow(radius: 1)
                                        .border(Color.kaBorder, width: 2)
                                }
                            }
                        }
                        .offset(x: -elapsedTime * 80)
                        .background(Color.kaGalleryBackground)
                    }
                    .scrollIndicators(.never)
                    .scrollEdgeEffectStyle(.none, for: .all)
                    .scrollEdgeEffectHidden(true)
                    .scrollDisabled(true)
                }
            }
            .rotationEffect(.degrees(180))
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                viewHeight = height
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
        descriptor.fetchLimit = Self.displayedWordCount * 10
        do {
            let wordImages = try modelContext.fetch(descriptor)
            filteredWordImages = Array(wordImages.shuffled().prefix(Self.displayedWordCount))
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
