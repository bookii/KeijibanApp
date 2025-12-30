import PhotosUI
import SwiftUI

public struct KAStreamView: View {
    private struct IdentifiableImage: Identifiable {
        let id: UUID = .init()
        let uiImage: UIImage

        init(_ uiImage: UIImage) {
            self.uiImage = uiImage
        }
    }

    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: IdentifiableImage?

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ContentView(columnCount: Int(proxy.size.width / 80))
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
        private let itemCount: Int = 20
        private let spacing: CGFloat = 12
        private let startDate = Date()
        private let baseScrollSpeed: CGFloat = 200
        private let columnCount: Int
        private let itemHeights: [[CGFloat]]
        private let columnHeights: [CGFloat]
        private let scrollSpeeds: [CGFloat]

        fileprivate init(columnCount: Int) {
            self.columnCount = columnCount

            var itemHeights: [[CGFloat]] = []
            var columnHeights: [CGFloat] = []
            var scrollSpeeds: [CGFloat] = []
            for columnIndex in 0 ..< columnCount {
                var itemHeightsInColumn: [CGFloat] = []
                var columnHeight: CGFloat = 0
                for rowIndex in 0 ..< itemCount {
                    let height = CGFloat((columnIndex + rowIndex) % itemCount + 50)
                    itemHeightsInColumn.append(height)
                    columnHeight += height + spacing
                }
                itemHeights.append(itemHeightsInColumn)
                columnHeights.append(columnHeight)
                scrollSpeeds.append(baseScrollSpeed * (0.8 + CGFloat(columnIndex) * 0.1))
            }
            self.itemHeights = itemHeights
            self.columnHeights = columnHeights
            self.scrollSpeeds = scrollSpeeds
        }

        fileprivate var body: some View {
            TimelineView(.animation) { context in
                let elapsedTime = context.date.timeIntervalSince(startDate)
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                        let columnHeight = columnHeights[columnIndex]
                        let scrollOffset = (elapsedTime * scrollSpeeds[columnIndex] + columnHeight).truncatingRemainder(dividingBy: columnHeight)
                        LazyVStack(spacing: spacing) {
                            ForEach(0 ..< itemCount * 2, id: \.self) { rowIndex in
                                Color(.systemGray)
                                    .frame(height: itemHeights[columnIndex][rowIndex % itemCount])
                                    .overlay {
                                        Text(String(rowIndex))
                                    }
                            }
                        }
                        .offset(y: scrollOffset - columnHeight)
                    }
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        KAStreamView()
            .environment(\.analyzerService, KAMockAnalyzerService())
    }
#endif
