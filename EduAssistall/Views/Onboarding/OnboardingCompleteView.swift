import SwiftUI

struct OnboardingCompleteView: View {
    let onFinish: () -> Void

    @State private var animateBadge = false

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateBadge ? 1.15 : 1.0)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
            }
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateBadge)
            .onAppear { animateBadge = true }

            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.largeTitle.bold())

                Text("Your personalized learning experience is ready. Let's get started!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onFinish) {
                Text("Go to Dashboard")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .hideBackButton()
    }
}
