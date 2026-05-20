import SwiftUI

// Replaces the former AI Training Consent screen (FR-404, removed per NYC DOE guidance).
// Students and parents must acknowledge AI usage, teacher visibility, and behavioral
// monitoring before accessing the companion for the first time.
struct AIDisclosureView: View {
    @Environment(AuthViewModel.self) private var authVM
    let onComplete: () -> Void

    @State private var hasConsented = false
    @State private var isSaving = false

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
                            title: "Powered by Anthropic's Claude",
                            detail: "Your learning companion is powered by a secure, third-party AI provider (Anthropic). In order to assist you, your chat messages, VARK learning styles, and grade level context must be securely sent to Anthropic. It will never use your data for advertising or model training."
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
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Sharing & Consent")
                            .font(.headline)
                        
                        Toggle(isOn: $hasConsented) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I grant permission to use my learning data")
                                    .font(.subheadline.bold())
                                Text("I agree to share my chat inputs, learning profile, and grade level with Anthropic via secure Cloud Functions to enable the AI companion. I understand I can revoke this consent at any time in Settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.automatic)
                        .padding(.vertical, 8)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }

            VStack(spacing: 0) {
                Divider()
                Button {
                    Task {
                        isSaving = true
                        try? await authVM.updateAIConsent(granted: true)
                        isSaving = false
                        onComplete()
                    }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Agree & Enable AI Companion")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasConsented ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundStyle(hasConsented ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!hasConsented || isSaving)
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
