import Foundation
import NaturalLanguage
import SwiftUI
import Vision

extension EnvironmentValues {
    @Entry var analyzerService: KAAnalyzerServiceProtocol = KAAnalyzerService.shared
}

public protocol KAAnalyzerServiceProtocol {
    func analyzeImage(_ uiImage: UIImage) async throws -> KAAnalyzeData?
}

public final class KAAnalyzerService: KAAnalyzerServiceProtocol {
    public static let shared = KAAnalyzerService()

    private init() {}

    public func analyzeImage(_ originalImage: UIImage) async throws -> KAAnalyzeData? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<KAAnalyzeData?, Error>) in
            guard let cgImage = originalImage.cgImage else {
                continuation.resume(returning: nil)
                return
            }

            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let tokenizer = NLTokenizer(unit: .word)
                var wordImages: [KAAnalyzeData.WordImage] = []
                for observation in observations {
                    // NOTE: VNRecognizeTextRequest の minimumTextHeight が効かないのでここで小さい文字を切り捨てる
                    guard observation.boundingBox.height >= 0.05 * (originalImage.size.width / originalImage.size.height),
                          let candidate = observation.topCandidates(1).first
                    else {
                        continue
                    }
                    let text = candidate.string
                    tokenizer.string = text
                    tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { range, _ in
                        guard let boundingBox = try? candidate.boundingBox(for: range)?.boundingBox else {
                            return true
                        }
                        let marginRatio: CGFloat = 0.05
                        let expandedBox = boundingBox.insetBy(dx: -marginRatio * boundingBox.width, dy: -marginRatio * boundingBox.height)

                        let previewRect = boundingBox.translateCoordinateFromVisionToPixel(in: originalImage.size)
                        let storedRect = expandedBox.translateCoordinateFromVisionToPixel(in: originalImage.size)

                        guard let previewImage = self.cropImage(originalImage, with: previewRect),
                              let storedImage = self.cropImage(originalImage, with: storedRect)
                        else {
                            return true
                        }
                        wordImages.append(.init(text: String(text[range]), storedImage: storedImage, previewImage: previewImage, originInOriginalImage: previewRect.origin))
                        return true
                    }
                }

                continuation.resume(returning: .init(originalImage: originalImage, wordImages: wordImages))
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja", "en"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func cropImage(_ image: UIImage, with rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage,
              let croppedCgImage = cgImage.cropping(to: rect)
        else {
            return nil
        }
        return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

private extension CGRect {
    func translateCoordinateFromVisionToPixel(in imageSize: CGSize) -> Self {
        // Vision の boundingBox は左下原点・正規化座標
        .init(x: origin.x * imageSize.width,
              y: (1 - origin.y - height) * imageSize.height,
              width: width * imageSize.width,
              height: height * imageSize.height)
    }
}

#if DEBUG
    public final class KAMockAnalyzerService: KAAnalyzerServiceProtocol {
        private let shouldFail: Bool

        public init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        public func analyzeImage(_: UIImage) async throws -> KAAnalyzeData? {
            try await Task.sleep(for: .seconds(1))
            if shouldFail {
                throw KALocalizedError.withMessage("Mock Failure")
            }
            return await KAAnalyzeData.mockAnalyzePreviewData()
        }
    }
#endif
