import SwiftUI

public struct IndexView: View {
    private enum ArrowDirection {
        case left
        case right
    }

    private struct ArrowHead: Shape {
        let direction: ArrowDirection

        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            switch direction {
            case .left:
                path.move(to: .init(x: rect.maxX, y: rect.minY))
                path.addLine(to: .init(x: rect.minX, y: (rect.maxY - rect.minY) / 2))
                path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
            case .right:
                path.move(to: .init(x: rect.minX, y: rect.minY))
                path.addLine(to: .init(x: rect.maxX, y: (rect.maxY - rect.minY) / 2))
                path.addLine(to: .init(x: rect.minX, y: rect.maxY))
            }
            return path
        }
    }

    @State private var boardBodyWidth: CGFloat?
    private var boardBodyHeight: CGFloat? {
        boardBodyWidth.map { $0 / 3 }
    }

    @State private var viewHeight: CGFloat?

    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGray2)
                .frame(width: 32)
            VStack(spacing: 24) {
                Color(uiColor: .systemGray)
                    .overlay(alignment: .leading) {
                        if let boardBodyHeight {
                            ArrowHead(direction: .left)
                                .fill(Color(uiColor: .systemGray))
                                .frame(width: boardBodyHeight / 4, height: boardBodyHeight)
                                .offset(x: -boardBodyHeight / 4)
                        }
                    }
                    .frame(width: boardBodyWidth, height: boardBodyHeight)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("文字あつめ")
                                .font(.title.bold())
                            Text("ここに説明文が入ります")
                                .font(.body)
                        }
                        .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                Color(uiColor: .systemGray)
                    .overlay(alignment: .trailing) {
                        if let boardBodyHeight {
                            ArrowHead(direction: .right)
                                .fill(Color(uiColor: .systemGray))
                                .frame(width: boardBodyHeight / 4, height: boardBodyHeight)
                                .offset(x: boardBodyHeight / 4)
                        }
                    }
                    .frame(width: boardBodyWidth, height: boardBodyHeight)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("ケイ字バン")
                                .font(.title.bold())
                            Text("ここに説明文が入ります")
                                .font(.body)
                        }
                        .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth: .infinity)
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
                boardBodyWidth = width
            }
            .offset(y: 16)
            .padding(.horizontal, 48)
        }
        .padding(.top, 32)
    }
}

#if DEBUG
    #Preview {
        IndexView()
    }
#endif
