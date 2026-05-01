import SwiftUI

// Replaces the former AI Training Consent screen (FR-404, removed per NYC DOE guidance).
// Students and parents must acknowledge AI usage, teacher visibility, and behavioral
// monitoring before accessing the companion for the first time.
struct AIDisclosureView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Your AI Companion")
                            .font(.largeTitle.bold())
                        Text("Please read before using the AI chat feature")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        DisclosurePoint(
                            icon: "brain.head.profile",
                            color: .blue,
                            title: "Powered by AI",
                            detail: "Your learning companion is an AI system powered by Claude (Anthropic). It can make mistakes — always verify important information with your teacher."
                        )
                        DisclosurePoint(
                            icon: "eye",
                            color: .indigo,
                            title: "Teachers and parents can see this",
                            detail: "Your teachers and linked parents can review your conversation history at any time. Never share passwords, phone numbers, addresses, or other personal information in chat."
                        )
                        DisclosurePoint(
                            icon: "chart.bar.doc.horizontal",
                            color: .orange,
                            title: "Supports your learning",
                            detail: "The AI notices when you may be feeling frustrated or stuck, and alerts your teacher so they can offer extra help. This is only used to support your learning — never for grades or discipline."
                        )
                        DisclosurePoint(
                            icon: "person.fill.checkmark",
                            color: .green,
                            title: "Not a counselor",
                            detail: "The AI cannot provide counseling or handle personal crises. If you are struggling emotionally or feel unsafe, please talk to a trusted adult, your school counselor, or call/text 988."
                        )
                        DisclosurePoint(
                            icon: "nosign",
                            color: .red,
                            title: "What AI cannot do",
                            detail: "AI is never used to make decisions about your grades, placement, discipline, or any official school records. Those decisions always involve a qualified human educator."
                        )
                    }
                }
                .padding(24)
            }

            VStack(spacing: 0) {
                Divider()
                Button(action: onComplete) {
                    Text("I Understand")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(Color.appGroupedBackground)
            }
        }
        .background(Color.appGroupedBackground)
    }
}

private struct DisclosurePoint: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
