import Foundation
import SwiftUI

public struct KAErrorAlertModifier: ViewModifier {
    private let onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Binding private var error: Error?
    private var localizedError: KALocalizedError? {
        if let localizedError = error as? KALocalizedError {
            localizedError
        } else if let error {
            KALocalizedError.wrapping(error)
        } else {
            nil
        }
    }

    public init(_ error: Binding<Error?>, onDismiss: (() -> Void)? = nil) {
        _error = error
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .alert(
                isPresented: Binding(
                    get: { localizedError != nil },
                    set: { isPresented in
                        if !isPresented {
                            error = nil
                        }
                    },
                ),
                error: localizedError,
            ) {
                Button("OK") {
                    onDismiss?()
                }
            }
    }
}

public extension View {
    func errorAlert(_ error: Binding<Error?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(KAErrorAlertModifier(error, onDismiss: onDismiss))
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var error: Error? = KALocalizedError.withMessage("Sample Error")
        Color.clear
            .errorAlert($error)
    }
#endif
