import PhotosUI
import SwiftData
import SwiftUI

public struct KAStreamView: View {
    private struct IdentifiableImage: Identifiable {
        let id: UUID = .init()
        let uiImage: UIImage

        init(_ uiImage: UIImage) {
            self.uiImage = uiImage
        }
    }

    private static let spacing: CGFloat = 12
    private static let startDate = Date()
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: IdentifiableImage?
    @Query private var wordImages: [KAStoredWordImage]

    public init() {}

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ContentView(wordImages: wordImages, columnCount: max(1, Int(proxy.size.width / 100)))
                    .ignoresSafeArea()
            }
            .padding(.horizontal, 12)
            .sheet(item: $pickedImage) {
                pickedImage = nil
            } content: { pickedImage in
                KAAnalyzerView(uiImage: pickedImage.uiImage)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("", systemImage: "plus")
                    }
                }
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

    private struct ContentView: View {
        private let wordImagesInColumns: [[KAStoredWordImage]]
        private var columnCount: Int {
            wordImagesInColumns.count
        }

        @State private var rowCounts: [Int: Int] = [:]

        fileprivate init(wordImages: [KAStoredWordImage], columnCount: Int) {
            let shuffledStoredWordImages = wordImages.shuffled()
            var wordImagesInColumns = Array(repeating: [KAStoredWordImage](), count: columnCount)
            for index in shuffledStoredWordImages.indices {
                wordImagesInColumns[index % columnCount].append(shuffledStoredWordImages[index])
            }
            self.wordImagesInColumns = wordImagesInColumns
            for columnIndex in wordImagesInColumns.indices {
                rowCounts[columnIndex] = wordImagesInColumns[columnIndex].count
            }
        }

        fileprivate var body: some View {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                    ColumnView(wordImages: wordImagesInColumns[columnIndex])
                }
            }
        }

        private func index(columnIndex: Int, rowIndex: Int) -> Int {
            columnIndex + rowIndex * columnCount
        }
    }

    private struct ColumnView: View {
        private let wordImages: [KAStoredWordImage]
        @State private var rowCount: Int
        @State private var viewWidth: CGFloat?

        fileprivate init(wordImages: [KAStoredWordImage]) {
            self.wordImages = wordImages
            _rowCount = .init(initialValue: wordImages.count)
        }

        fileprivate var body: some View {
            TimelineView(.animation) { context in
                if !wordImages.isEmpty {
                    let elapsedTime = context.date.timeIntervalSince(startDate)
                    ScrollView {
                        LazyVStack(spacing: spacing) {
                            ForEach(0 ..< rowCount, id: \.self) { rowIndex in
                                let wordImage = wordImages[rowIndex % wordImages.count]
                                Button {} label: {
                                    LazyImage(data: wordImage.imageData)
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

    private struct LazyImage: View {
        private let data: Data
        @State private var uiImage: UIImage?

        fileprivate init(data: Data) {
            self.data = data
        }

        fileprivate var body: some View {
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
}

#if DEBUG
    #Preview {
        @Previewable @State var modelContainer: ModelContainer?
        Group {
            if let modelContainer {
                KAStreamView()
                    .modelContainer(modelContainer)
            } else {
                Color.clear
                    .task {
                        do {
                            let container = try ModelContainer(for: KAStoredWordImage.self, configurations: .init(isStoredInMemoryOnly: true))
                            let storedWordImages = await KAAnalyzeData.mockAnalyzePreviewData().wordImages.compactMap { wordImage in
                                try? KAStoredWordImage(analyzedWordImage: wordImage, board: .mockBoards.first!)
                            }
                            for storedWordImage in storedWordImages {
                                container.mainContext.insert(storedWordImage)
                            }
                            modelContainer = container
                        } catch {
                            fatalError("Failed to init modelContainer: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }
#endif
