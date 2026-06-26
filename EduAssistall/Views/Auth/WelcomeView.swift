import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    @State private var currentPage = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "graduationcap.fill",
            headline: "Learning that fits every student",
            body: "EduAssist uses AI to understand each student's unique learning style, then recommends personalized content — always with a teacher or parent reviewing first.",
            accent: Color.blue
        ),
        WelcomePage(
            icon: "brain.head.profile",
            headline: "Assess. Recommend. Approve.",
            body: "Step 1: Discover how you learn best. Step 2: AI suggests next steps. Step 3: Your teacher or parent approves before anything reaches you.",
            accent: Color.purple
        ),
        WelcomePage(
            icon: "person.3.fill",
            headline: "Built for every role",
            body: "Students explore and grow. Teachers monitor and guide. Parents stay informed and in control. Everyone has the right view.",
            accent: Color.teal
        ),
        WelcomePage(
            icon: "checkmark.shield.fill",
            headline: "Human oversight, always",
            body: "No AI recommendation ever reaches a student without explicit approval from a trusted adult. That's not a feature — it's the foundation.",
            accent: Color.green
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { i in
                    WelcomePageView(page: pages[i], currentPage: currentPage)
                        .tag(i)
                }
            }
            .welcomeTabViewStyle()
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Pill page indicators
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? pages[currentPage].accent : Color.secondary.opacity(0.25))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }

                if currentPage < pages.count - 1 {
                    HStack(spacing: 12) {
                        Button("Skip") { onGetStarted() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(pages[currentPage].accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 28)
                } else {
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(pages[currentPage].accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 28)
                }
            }
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
    }
}

// MARK: - Page Model

private struct WelcomePage {
    let icon: String
    let headline: String
    let body: String
    let accent: Color
}

// MARK: - Page View

private struct WelcomePageView: View {
    let page: WelcomePage
    let currentPage: Int

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.accent.opacity(0.18), page.accent.opacity(0.04)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.accent.opacity(0.22), page.accent.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.accent, page.accent.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: currentPage)
            }

            VStack(spacing: 14) {
                Text(page.headline)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
