import Foundation
import NaturalLanguage
import SwiftUI
import Vision

extension EnvironmentValues {
    @Entry var analyzerService: KAAnalyzerServiceProtocol = KAAnalyzerService.shared
}

public protocol KAAnalyzerServiceProtocol {
    func analyzeImage(_ uiImage: UIImage) async throws -> [KAWordImage]
}

public final class KAAnalyzerService: KAAnalyzerServiceProtocol {
    public static let shared = KAAnalyzerService()

    private init() {}

    public func analyzeImage(_ uiImage: UIImage) async throws -> [KAWordImage] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] request, _ in
                guard let self, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let tokenizer = NLTokenizer(unit: .word)
                var wordImages: [KAWordImage] = []
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else {
                        continue
                    }
                    let text = candidate.string
                    tokenizer.string = text
                    tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { range, _ in
                        guard let box = try? candidate.boundingBox(for: range)?.boundingBox,
                              let letterImage = self.cropImage(uiImage, with: box),
                              let imageData = letterImage.jpegData(compressionQuality: 0.9)
                        else {
                            return true
                        }
                        wordImages.append(.init(id: UUID(), text: String(text[range]), imageData: imageData))
                        return true
                    }
                }
                continuation.resume(returning: wordImages)
            }
        }
    }

    private func cropImage(_ image: UIImage, with boundingBox: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let marginRatio: CGFloat = 0.05
        let expandedBox = boundingBox.insetBy(dx: -CGFloat(marginRatio) * boundingBox.width,
                                              dy: -CGFloat(marginRatio) * boundingBox.height)
        // VisionのboundingBoxは左下原点・正規化座標
        let rect = CGRect(x: expandedBox.origin.x * width,
                          y: (1 - expandedBox.origin.y - expandedBox.height) * height,
                          width: expandedBox.width * width,
                          height: expandedBox.height * height)
        guard let croppedCgImage = cgImage.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

#if DEBUG
    public final class KAMockAnalyzerService: KAAnalyzerServiceProtocol {
        private let shouldFail: Bool

        public init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        public func analyzeImage(_: UIImage) async throws -> [KAWordImage] {
            try await Task.sleep(for: .seconds(1))
            if shouldFail {
                throw KALocalizedError.withMessage("Mock Failure")
            }
            return await KAWordImage.mockWordImages()
        }
    }
#endif
