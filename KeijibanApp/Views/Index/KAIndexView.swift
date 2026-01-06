import SwiftUI

public struct KAIndexView: View {
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

    @State private var viewHeight: CGFloat?
    private var boardBodyHeight: CGFloat? { viewHeight.map { $0 / 4 } }
    private var boardBodyWidth: CGFloat? {
        viewHeight
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGray2)
                .frame(width: 32)
                .ignoresSafeArea()
            VStack(spacing: 16) {
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
                            Text("ミュー字アム")
                                .font(.kuramubon(size: 32))
                            Text("日常にあふれる字を記録しよう")
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
                                .font(.kuramubon(size: 32))
                            Text("みんなで楽しむ字のひろば")
                        }
                        .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth: .infinity)
            }
            .offset(y: 16)
        }
        .padding(.top, 24)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            viewHeight = height
        }
    }
}

#if DEBUG
    #Preview {
        KAIndexView()
    }
#endif
