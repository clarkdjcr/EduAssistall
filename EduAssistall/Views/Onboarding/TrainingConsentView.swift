import SwiftUI

struct TrainingConsentView: View {
    let userId: String
    let onComplete: (Bool) -> Void   // passes the chosen consent value

    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Improvement Consent")
                            .font(.largeTitle.bold())
                        Text("Help make EduAssist better for every student")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ConsentPoint(
                            icon: "brain",
                            color: .blue,
                            title: "What this covers",
                            detail: "Your anonymised conversation summaries may be used to improve future versions of the educational AI — for example, making explanations clearer for your grade level."
                        )
                        ConsentPoint(
                            icon: "eye.slash",
                            color: .green,
                            title: "What is never shared",
                            detail: "Your name, email, school, or any personally identifiable information is never included. All data is stripped of identity before any analysis."
                        )
                        ConsentPoint(
                            icon: "arrow.uturn.backward",
                            color: .orange,
                            title: "You can change your mind",
                            detail: "You can withdraw this consent at any time from Settings → Privacy & Data. Withdrawing consent does not affect your access to EduAssist."
                        )
                    }

                    Text("This consent is optional. EduAssist works exactly the same whether you choose to help or not.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(24)
            }

            VStack(spacing: 12) {
                Button {
                    save(consent: true)
                } label: {
                    Text("Allow — Help Improve EduAssist")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSaving)

                Button {
                    save(consent: false)
                } label: {
                    Text("Don't Allow")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .disabled(isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appGroupedBackground)
        }
        .background(Color.appGroupedBackground)
    }

    private func save(consent: Bool) {
        isSaving = true
        Task {
            try? await FirestoreService.shared.updateTrainingConsent(userId: userId, consent: consent)
            onComplete(consent)
        }
    }
}

private struct ConsentPoint: View {
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
