import Foundation
import UIKit

public extension UIImage {
    func resized(toFit size: CGSize) -> UIImage? {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)

        let newSize = CGSize(
            width: self.size.width * aspectRatio,
            height: self.size.height * aspectRatio,
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    #if DEBUG
        convenience init?(url: URL) async throws {
            let request = URLRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: request)
            self.init(data: data)
        }

        static func mockImage() async -> UIImage {
            guard let url = URL(string: "https://i.gyazo.com/8aa54bec5de48bece70186bfaf3c5e57.png"),
                  let image = try? await UIImage(url: url)
            else {
                fatalError("Failed to load image")
            }
            return image
        }
    #endif
}
