import SwiftUI

extension Font {
    static func kiyosuna(size: CGFloat, weight: Font.Weight = .regular) -> Self {
        switch weight {
        case .bold:
            .custom("KTKiyosunaSans-Bold", size: size)
        default:
            .custom("KTKiyosunaSans-Light", size: size)
        }
    }

    static func kuramubon(size: CGFloat) -> Self {
        .custom("Kuramubon", size: size)
    }

    static func stick(size: CGFloat) -> Self {
        .custom("Stick-Regular", size: size)
    }
}
