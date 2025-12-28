import SwiftUI

public struct KAStreamView: View {
    public var body: some View {
        GeometryReader { proxy in
            ContentView(columnCount: Int(proxy.size.width / 80))
        }
        .ignoresSafeArea()
        .padding(.horizontal, 12)
    }
}

private struct ContentView: View {
    private let itemCount: Int = 20
    private let spacing: CGFloat = 12
    private let startDate = Date()
    private let baseScrollSpeed: CGFloat = 200
    private let itemHeights: [[CGFloat]]
    private let columnHeights: [CGFloat]
    private let columnCount: Int

    fileprivate init(columnCount: Int) {
        self.columnCount = columnCount

        var itemHeights: [[CGFloat]] = []
        var columnHeights: [CGFloat] = []
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
        }
        self.itemHeights = itemHeights
        self.columnHeights = columnHeights
    }

    fileprivate var body: some View {
        TimelineView(.animation) { context in
            let elapsedTime = context.date.timeIntervalSince(startDate)
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                    let columnHeight = columnHeights[columnIndex]
                    let scrollSpeed = baseScrollSpeed * (0.8 + CGFloat(columnIndex) * 0.1)
                    let scrollOffset = (elapsedTime * scrollSpeed).truncatingRemainder(dividingBy: columnHeight)
                    VStack(spacing: spacing) {
                        ForEach(0 ..< itemCount * 2, id: \.self) { rowIndex in
                            Color.blue
                                .frame(height: itemHeights[columnIndex][rowIndex % itemCount])
                        }
                    }
                    .offset(y: scrollOffset - columnHeight)
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        KAStreamView()
    }
#endif
