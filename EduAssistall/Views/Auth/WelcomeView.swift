import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    @State private var currentPage = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "graduationcap.fill",
            iconColor: .blue,
            headline: "Learning that fits every student",
            body: "EduAssist uses AI to understand each student's unique learning style, then recommends personalized content — always with a teacher or parent reviewing first.",
            accent: Color.blue
        ),
        WelcomePage(
            icon: "brain.head.profile",
            iconColor: .purple,
            headline: "Assess. Recommend. Approve.",
            body: "Step 1: Discover how you learn best. Step 2: AI suggests next steps. Step 3: Your teacher or parent approves before anything reaches you.",
            accent: Color.purple
        ),
        WelcomePage(
            icon: "person.3.fill",
            iconColor: .teal,
            headline: "Built for every role",
            body: "Students explore and grow. Teachers monitor and guide. Parents stay informed and in control. Everyone has the right view.",
            accent: Color.teal
        ),
        WelcomePage(
            icon: "checkmark.shield.fill",
            iconColor: .green,
            headline: "Human oversight, always",
            body: "No AI recommendation ever reaches a student without explicit approval from a trusted adult. That's not a feature — it's the foundation.",
            accent: Color.green
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { i in
                    WelcomePageView(page: pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.blue : Color.secondary.opacity(0.3))
                            .frame(width: i == currentPage ? 10 : 7, height: i == currentPage ? 10 : 7)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }

                if currentPage < pages.count - 1 {
                    HStack(spacing: 12) {
                        Button("Skip") { onGetStarted() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
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
                            .background(Color.blue)
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

// MARK: - Page

private struct WelcomePage {
    let icon: String
    let iconColor: Color
    let headline: String
    let body: String
    let accent: Color
}

private struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.accent)
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
