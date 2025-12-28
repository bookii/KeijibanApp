import SwiftUI

public struct KAStreamView: View {
    private let startDate = Date()
    private let scrollSpeed: CGFloat = 50
    private let itemCount: Int = 10
    private let spacing: CGFloat = 12
    @State private var viewWidth: CGFloat?

    public var body: some View {
        TimelineView(.animation) { context in
            if let viewWidth {
                let columnCount = Int(viewWidth / 80)
                let elapsedTime = context.date.timeIntervalSince(startDate)
                HStack(spacing: spacing) {
                    ForEach(0 ..< columnCount, id: \.self) { columnIndex in
                        let baseOffset = elapsedTime * scrollSpeed * (1 + CGFloat(columnIndex % 3) * 0.2)
                        let offset = baseOffset.truncatingRemainder(dividingBy: columnHeight(columnIndex: columnIndex))
                        VStack(spacing: spacing) {
                            ForEach(0 ..< itemCount * 4, id: \.self) { rowIndex in
                                Color.blue
                                    .frame(height: itemHeight(columnIndex: columnIndex, rowIndex: rowIndex))
                            }
                        }
                        .offset(y: offset)
                    }
                }
            } else {
                Color.clear
            }
        }
        .padding(.horizontal, 12)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
            if viewWidth == nil {
                viewWidth = width
            }
        }
    }

    private func itemHeight(columnIndex: Int, rowIndex: Int) -> CGFloat {
        CGFloat((columnIndex + rowIndex) * 35 % 50 + 50)
    }

    private func columnHeight(columnIndex: Int) -> CGFloat {
        let heights = (0 ..< itemCount).map { itemHeight(columnIndex: columnIndex, rowIndex: $0) }
        return heights.reduce(0, +) + spacing * CGFloat(itemCount)
    }
}

#if DEBUG
    #Preview {
        KAStreamView()
    }
#endif
