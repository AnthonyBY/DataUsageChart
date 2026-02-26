import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            Text(message).multilineTextAlignment(.center)
            Button("Retry") { onRetry() }
        }
        .padding()
    }
}

#Preview {
    ErrorStateView(message: "Something went wrong. Please try again.", onRetry: {})
}
